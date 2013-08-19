package Siebel::Srvrmgr::Daemon::Light;

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon - class for interactive sessions with Siebel srvrmgr program

=head1 SYNOPSIS

    use Siebel::Srvrmgr::Daemon;

    my $daemon = Siebel::Srvrmgr::Daemon->new(
        {
            server      => 'servername',
            gateway     => 'gateway',
            enterprise  => 'enterprise',
            user        => 'user',
            password    => 'password',
            bin         => 'c:\\siebel\\client\\bin\\srvrmgr.exe',
            is_infinite => 1,
			commands    => [
			        Siebel::Srvrmgr::Daemon::Command->new(
                        command => 'load preferences',
                        action  => 'LoadPreferences'
                    ),
                    Siebel::Srvrmgr::Daemon::Command->new(
                        command => 'list comp type',
                        action  => 'ListCompTypes',
                        params  => [$comp_types_file]
                    ),
                    Siebel::Srvrmgr::Daemon::Command->new(
                        command => 'list comp',
                        action  => 'ListComps',
                        params  => [$comps_file]
                    ),
                    Siebel::Srvrmgr::Daemon::Command->new(
                        command => 'list comp def',
                        action  => 'ListCompDef',
                        params  => [$comps_defs_file]
                    )
                ]
        }
    );


=head1 DESCRIPTION

This class is used to execute the C<srvrmgr> program and execute commands through it.

The sessions are not "interactive" from the user point of view but the usage of this class enable the adoption of some logic to change how the commands will be executed or
even generate commands on the fly.

The logic behind this class is easy: you can submit a pair of command/action to the class. It will then connect to the server by executing C<srvrmgr>, submit the command to the server
and recover the output generated. The action will be executed having this output as parameter. Anything could be considered as an action, from simple storing the output to even generating
new commands to be executed in the server.

A command is any command supported from C<srvrmgr> program. An action can be any class but is obligatory to create a subclass of L<Siebel::Srvrmgr::Daemon::Action> base class. See the <commands>
attribute for details.

The object will create an loop to interact with the C<srvrmgr> program to execute the commands and actions as requested. This loop might be infinite, where the C<commands> attribute will be restarted when the
stack is finished.

The C<srvrmgr> program will be executed by using IPC: this means that this method should be portable. Once the connection is made (see the C<run> method) it will not be dropped after commands execution but it will
be done automatically when the instance of this class goes out of scope. The instance is also able to deal with C<INT> signal and close connection as appropriate: the class will first try to submit a C<exit> command
through C<srvrmgr> program and if it's not terminated automatically the PID will be ripped.

Logging of this class can be enabled by using L<Siebel::Srvrmgr> logging feature.

This module is based on L<IPC::Open3::Callback> from Lucas Theisen (see SEE ALSO section).

=cut

use Moose;
use namespace::autoclean;
use Siebel::Srvrmgr::Daemon::ActionFactory;
use Siebel::Srvrmgr::ListParser;
use Siebel::Srvrmgr::Regexes
  qw(SRVRMGR_PROMPT LOAD_PREF_RESP SIEBEL_ERROR ROWS_RETURNED);
use Siebel::Srvrmgr::Daemon::Command;
use POSIX ":sys_wait_h";
use feature qw(say switch);
use Log::Log4perl;
use Siebel::Srvrmgr;
use Scalar::Util qw(weaken openhandle);
use Config;
use Carp qw(longmess);
use File::Temp qw(:POSIX);

extends 'Siebel::Srvrmgr::Daemon';

=pod

=head1 ATTRIBUTES

=cut

has output_file => (
    is     => 'Str',
    isa    => 'ro',
    reader => 'get_output_file',
    writer => '_set_output_file'
);

=pod

=head1 METHODS

=head2 get_output_file

Returns the content of the C<output_file> attribute.

=head2 run

This method will try to connect to a Siebel Enterprise through C<srvrmgr> program (if it is the first time the method is invoke) or reuse an already open
connection to submit the commands and respective actions defined during object creation. The path to the program is check and if it does not exists the 
method will issue an warning message and immediatly returns false.

Those operations will be executed in a loop as long the C<check> method from the class L<Siebel::Srvrmgr::Daemon::Condition> returns true.

Beware that Siebel::Srvrmgr::Daemon uses a B<single instance> of a L<Siebel::Srvrmgr::ListParser> class to process the parsing requests, so it is not possible
to execute L<Siebel::Srvrmgr::Daemon::Command> instances in parallel.

=cut

sub run {

    my $self = shift;

    my $logger = __PACKAGE__->gimme_logger();
    weaken($logger);
    $logger->info('Starting run method');

    my $parser = Siebel::Srvrmgr::ListParser->new();

    exit 1 if ($SIG_INT);

    my $pid = system( $self->_define_params() );

    open( my $in, '<', $self->get_output_file() )
      or die( 'Cannot read ' . $self->get_output_file() . ': ' . $! );
    my @input_buffer = <$in>;
    close($in);

    # below is the place for a Action object
    if ( scalar(@input_buffer) >= 1 ) {

        $parser->parse( \@input_buffer );

        if ( $parser->has_tree() ) {

            if ( $logger->is_debug() ) {

                $logger->debug( 'Parsed '
                      . $parser->count_parsed()
                      . ' commands and their respective output' );

            }

            foreach my $command ( keys( $parser->get_parsed_tree() ) ) {

                my $cmd = $self->shift_command();

                my $action = Siebel::Srvrmgr::Daemon::ActionFactory->create(
                    $cmd->get_action(),
                    {
                        parser => $parser,
                        params => $cmd->get_params()

                    }
                );

            }

        }
        else {

            $logger->fatal('Parser did have a parsed tree after parsing');

        }

    }
    else {

        $logger->debug('buffer is empty');

    }

    $logger->debug('Preparing to execute command')
      if ( $logger->is_debug() );

    $self->_set_child_runs( $self->get_child_runs() + 1 );
    $logger->debug( 'child_runs = ' . $self->get_child_runs() )
      if ( $logger->is_debug() );
    $logger->info('Exiting run sub');

    return 1;

}

override _define_params => sub {

    my $self = shift;

    my $params_ref = super();

    my ( $fh, $input_file ) = tmpnam();

    foreach my $cmd ( @{ $self->get_commands() } ) {

        $self->_check_cmd( $cmd->get_command() );
        print $fh $cmd->get_command(), "\n";

    }

    close($fh);

    $self->_set_output_file( scalar( tmpnam() ) );

    push( @{$params_ref},
        '/b', '/i', $input_file, '/o', $self->get_output_file() );

    return $params_ref;

};

sub _check_child {

    my $self   = shift;
    my $logger = shift;
    weaken($logger);

    if ( $self->has_pid() ) {

        # try to read immediatly from stderr if possible
        if ( openhandle( $self->get_error() ) ) {

            my $error;

            my $select = IO::Select->new();
            $select->add( $self->get_error() );

            while ( my $fh = $select->can_read( $self->get_read_timeout() ) ) {

                my $buffer;
                my $read = sysread( $fh, $buffer, $self->get_buffer_size() );

                if ( defined($read) ) {

                    if ( $read > 0 ) {

                        $error .= $buffer;
                        next;

                    }
                    else {

                        $logger->debug(
                            'Reached EOF while trying to get error messages')
                          if ( $logger->is_debug() );

                    }

                }
                else {

                    $logger->warn(
                        'Could not sysread the STDERR from srvrmgr process: '
                          . $! );
                    last;

                }

            }    # end of while block

            $self->_process_stderr( \$error, $logger ) if ( defined($error) );

        }
        else {

            $logger->fatal('Error pipe from child is closed');

        }

        $logger->fatal('Read pipe from child is closed')
          unless ( openhandle( $self->get_read() ) );
        $logger->fatal('Write pipe from child is closed')
          unless ( openhandle( $self->get_write() ) );

# :WORKAROUND:19/4/2012 19:38:04:: somehow the child process of srvrmgr has to be waited for one second and receive one kill 0 signal before
# it dies when something goes wrong
#        sleep 1;
        kill 0, $self->get_pid();

        unless ( kill 0, $self->get_pid() ) {

            $logger->fatal( $self->get_bin()
                  . " process returned a fatal error: ${^CHILD_ERROR_NATIVE}" );

            $logger->fatal( $? . ' child exit status = ' . ( $? >> 8 ) );

            $self->close_child($logger);

            return 0;

        }
        else {

            return 1;

        }

    }    # end of if has_pid
    else {

        return 0;

    }

}

=pod

=head2 DEMOLISH

This method is invoked before the object instance is destroyed. It will try to close the connection with the Siebel Enterprise (if opened)
by submitting the command C<exit>.

It will then try to read the string "Disconnecting from server" from the generated output after the command submission and closing the opened
filehandles right after. Then it will send a C<kill 0> signal to the process to check if it is still running.

Finally, it will wait for 5 seconds before calling C<waitpid> function to rip the child process.

=cut

sub DEMOLISH {

    my $self = shift;

    my $logger = __PACKAGE__->gimme_logger();
    weaken($logger);

    $logger->info('Terminating daemon');

    if ( $self->has_pid() and ( $self->get_pid() =~ /\d+/ ) ) {

        $self->close_child($logger);

    }
    else {

        if ( $logger->is_info() ) {

            $logger->info("Program termination was forced") if ($SIG_ALARM);
            $logger->info(
'srvrmgr program was not yet executed, no child process to terminate'
            );
            $logger->info('daemon says bye-bye');

        }

    }

}

sub _term_INT {

    $SIG_INT = 1;

}

sub _term_PIPE {

    $SIG_PIPE = 1;
    warn "got SIGPIPE\n";

}

sub _term_ALARM {

    $SIG_ALARM = 1;

}

=pod

=head2 gimme_logger

This method returns a L<Log::Log4perl::Logger> object as defined for L<Siebel::Srvrmgr> module.

It can be invoke both from a instance of Siebel::Srvrmgr::Daemon and the package itself.

=cut

sub gimme_logger {

    my $cfg = Siebel::Srvrmgr->logging_cfg();

    die "Could not start logging facilities"
      unless ( Log::Log4perl->init_once( \$cfg ) );

    return Log::Log4perl->get_logger('Siebel::Srvrmgr::Daemon');

}

=pod

=head1 CAVEATS

This class is still considered experimental and should be used with care.

The C<srvrmgr> program uses buffering, which makes difficult to read the generated output as expected.

=head1 SEE ALSO

=over 7 

=item *

L<Moose>

=item *

L<Siebel::Srvrmgr::Daemon::Condition>

=item *

L<Siebel::Srvrmgr::Daemon::Command>

=item *

L<Siebel::Srvrmgr::Daemon::ActionFactory>

=item *

L<Siebel::Srvrmgr::ListParser>

=item *

L<Siebel::Srvrmgr::Regexes>

=item *

L<POSIX>

=item *

L<Siebel::Srvrmgr::Daemon::Command>

=item *

L<https://github.com/lucastheisen/ipc-open3-callback>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.org<E<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.org<E<gt>

This file is part of Siebel Monitoring Tools.

Siebel Monitoring Tools is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel Monitoring Tools is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Siebel Monitoring Tools.  If not, see <http://www.gnu.org/licenses/>.

=cut

__PACKAGE__->meta->make_immutable;

1;

