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
use POSIX;
use feature qw(say switch);
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

has input_file => (
    is     => 'Str',
    isa    => 'ro',
    reader => 'get_input_file',
    writer => '_set_input_file'
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

    my $ret_code = system( $self->_define_params() );

    $self->_check_system( $logger, ${^CHILD_ERROR_NATIVE}, $ret_code, $? );

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

    $self->_set_child_runs( $self->get_child_runs() + 1 );
    $logger->debug( 'child_runs = ' . $self->get_child_runs() )
      if ( $logger->is_debug() );
    $logger->info('Exiting run sub');

    return 1;

}

override _my_cleanup => sub {

    my $self = shift;

    return $self->_del_input_file() && $self->_del_output_file();

};

sub _del_file {

    my $self     = shift;
    my $filename = shift;

    if ( -e $filename ) {

        my $ret = unlink $filename;

        if ($ret) {

            return 1;

        }
        else {

            warn "Could not remove $filename: $!";
            return 0;

        }

    }
    else {

        warn "File $filename does not exists";
        return 0;

    }

}

sub _del_input_file {

    my $self = shift;

    return $self->_del_file( $self->get_input_file() );

}

sub _del_output_file {

    my $self = shift;

    return $self->_del_file( $self->get_output_file() );

}

override _setup_commands => sub {

    my $self = shift;

    my ( $fh, $input_file ) = tmpnam();

    foreach my $cmd ( @{ $self->get_commands() } ) {

        $self->_check_cmd( $cmd->get_command() );
        print $fh $cmd->get_command(), "\n";

    }

    close($fh);

    $self->_set_input_file($input_file);

};

override _define_params => sub {

    my $self = shift;

    my $params_ref = super();

# :TODO      :20/08/2013 12:31:36:: must define if the output files must be kept or removed
    $self->_set_output_file( scalar( tmpnam() ) );

    push(
        @{$params_ref},
        '/b', '/i', $self->get_input_file(),
        '/o', $self->get_output_file()
    );

    return $params_ref;

};

sub _check_system {

    my $self   = shift;
    my $logger = shift;
    weaken($logger);
    my $child_error = shift;
    my $ret_code    = shift;
    my $error_code  = shift;

    given ($child_error) {

        when ( WIFEXITED($child_error) ) {

            $logger->info(
                'Child process terminate successfully with return code = '
                  . WEXITSTATUS($child_error) );

        }

        when ( WIFSIGNALED($child_error) ) {

            $logger->logdie( 'Child process terminated due signal: '
                  . WTERMSIG($child_error) );

        }

        when ( WIFSTOPPED($child_error) ) {

            $logger->logdie(
                'Child process was stopped with ' . WSTOPSIG($child_error) );

        }

        default {

            # shouldn't be necessary due WIFEXITED
            if ( $ret_code == 0 ) {

                $logger->info(
                    'Child process terminate successfully with return code = '
                      . WEXITSTATUS($child_error) );

            }
            else {

                $logger->logdie(
                    'system failed to execute srvrmgr: ' . $error_code );

            }

        }

    }

    return 1;

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

