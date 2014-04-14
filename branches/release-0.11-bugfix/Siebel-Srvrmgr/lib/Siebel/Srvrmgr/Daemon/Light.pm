package Siebel::Srvrmgr::Daemon::Light;

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon::Light - class for running commmands with Siebel srvrmgr program

=head1 SYNOPSIS

    use Siebel::Srvrmgr::Daemon::Light;

    my $daemon = Siebel::Srvrmgr::Daemon::Light->new(
        {
            server      => 'servername',
            gateway     => 'gateway',
            enterprise  => 'enterprise',
            user        => 'user',
            password    => 'password',
            bin         => 'c:\\siebel\\client\\bin\\srvrmgr.exe',
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

This is a subclass of L<Siebel::Srvrmgr::Daemon> used to execute the C<srvrmgr> program in batch mode. For a better understanding of what batch mode means, 
check out srvrmgr documentation.

This class is recomended for cases where it is not necessary to run several commmands through srvrmgr in a short period of time because in batch mode it will
connect to the Siebel Gateway, execute the commands configured and exit, avoiding keeping a connection opened for a long time. For UNIX-like OS, this class
would be a good choice for using with Inetd and Xinetd daemons.

This class is also highly recommended for OS plataforms like Microsoft Windows where IPC is not reliable enough, since this class uses C<system> instead of
L<IPC::Open3>.

=cut

use Moose;
use namespace::autoclean;
use Siebel::Srvrmgr::Daemon::ActionFactory;
use Siebel::Srvrmgr::ListParser;
use Siebel::Srvrmgr::Daemon::Command;
use POSIX;
use Scalar::Util qw(weaken);
use Config;
use Carp qw(longmess);
use File::Temp;
use Data::Dumper;
use Siebel::Srvrmgr;

extends 'Siebel::Srvrmgr::Daemon';

=pod

=head1 ATTRIBUTES

=head2 output_file

A string that represents the "/o" command line parameter of srvrmgr. It is defined internally, so it is read-only.

=cut

has output_file => (
    isa    => 'Str',
    is     => 'ro',
    reader => 'get_output_file',
    writer => '_set_output_file'
);

=pod

=head2 input_file

A string that represents the "/i" command line parameter of srvrmgr. It is defined internally, so it is read-only.

=cut

has input_file => (
    isa    => 'Str',
    is     => 'ro',
    reader => 'get_input_file',
    writer => '_set_input_file'
);

=pod

=head1 METHODS

=head2 get_output_file

Returns the content of the C<output_file> attribute.

=head2 get_input_file

Returns the content of the C<input_file> attribute.

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

    my $logger = Siebel::Srvrmgr->gimme_logger( ref($self) );
    weaken($logger);
    $logger->info('Starting run method');

    my $parser = Siebel::Srvrmgr::ListParser->new();

    if ( $logger->is_debug() ) {

        $logger->debug( 'Calling system with the following parameters: '
              . Dumper( $self->_define_params() ) );
        $logger->debug(
            'Commands to be execute are: ' . Dumper( $self->get_commands() ) );

    }

    my $ret_code = system( @{ $self->_define_params() } );

    $self->_check_system( $logger, ${^CHILD_ERROR_NATIVE}, $ret_code, $? );

    open( my $in, '<', $self->get_output_file() )
      or
      $logger->logdie( 'Cannot read ' . $self->get_output_file() . ': ' . $! );
    my @input_buffer = <$in>;
    close($in);

    if ( scalar(@input_buffer) >= 1 ) {

        $self->normalize_eol( \@input_buffer );
        chomp(@input_buffer);

# since we should have all output, we parse everything first to call each action after
        $parser->parse( \@input_buffer );

        if ( $parser->has_tree() ) {

            my $total = $self->cmds_vs_tree( $parser->count_parsed() );

            if ( $logger->is_debug() ) {

                $logger->debug( 'Total number of parsed items = '
                      . $parser->count_parsed() );
                $logger->debug( 'Total number of submitted commands = '
                      . scalar( @{ $self->get_commands() } ) );

            }

            $logger->logdie(
'Number of parsed nodes is different from the number of submitted commands'
            ) unless ( defined($total) );

            my $parsed_ref = $parser->get_parsed_tree();
            $parser->clear_parsed_tree();

            for ( my $i = 0 ; $i < $total ; $i++ ) {

                my $cmd = ( @{ $self->get_commands() } )[$i];

                my $action = Siebel::Srvrmgr::Daemon::ActionFactory->create(
                    $cmd->get_action(),
                    {
                        parser => $parser,
                        params => $cmd->get_params()

                    }
                );

                $action->do_parsed( $parsed_ref->[$i] );

            }

        }
        else {

            $logger->logdie('Parser did not have a parsed tree after parsing');

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

=pod

=head2 cmds_vs_tree

Expects the number of parsed nodes as parameter.

This method compares the number of C<commands> defined in a instance of this class with the number of nodes passed as parameter.

If their are equal, the number is returned. If their are different (and there is a problem with the parsed output of srvrmgr) this method
returns C<undef>.

=cut

sub cmds_vs_tree {

    my $self      = shift;
    my $nodes_num = shift;

    my $cmds_num = scalar( @{ $self->get_commands() } );

    if ( $cmds_num == $nodes_num ) {

        return $nodes_num;

    }
    else {

        return undef;

    }

}

override _my_cleanup => sub {

    my $self = shift;

    return $self->_del_input_file() && $self->_del_output_file();

};

sub _del_file {

    my $self     = shift;
    my $filename = shift;

    if ( defined($filename) ) {
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

# :WORKAROUND:03/10/2013 03:06:41:: getting a "tmpnam redefined" warning in Perl 5.18
    my ( $fh, $input_file ) = File::Temp::tmpnam();

    foreach my $cmd ( @{ $self->get_commands() } ) {

        $self->_check_cmd( $cmd->get_command() );
        print $fh $cmd->get_command(), "\n";

    }

    close($fh);

    $self->_set_input_file($input_file);

};

=pod

=head2 shift_commands

Overrided from parent class.

If the first command is a LOAD PREFERENCES, the C<commands> attribute will not be shifted and the method returns C<undef>.

Otherwise, the same behaviour from parent will be executed.

=cut

override shift_commands => sub {

    my $self = shift;

    if ( $self->get_commands()->[0]->get_command() =~ /load\spreferences/i ) {

        return undef;

    }
    else {

        return super();

    }

};

override _define_params => sub {

    my $self = shift;

    my $params_ref = super();

# :TODO      :20/08/2013 12:31:36:: must define if the output files must be kept or removed
    $self->_set_output_file( scalar( File::Temp::tmpnam() ) );

    push(
        @{$params_ref},
        '/b', '/i', $self->get_input_file(),
        '/o', $self->get_output_file()
    );

    return $params_ref;

};

# :TODO:18-10-2013:arfreitas: this should be done by IPC.pm module?
sub _manual_check {

    my $self   = shift;
    my $logger = shift;
    weaken($logger);
    my $ret_code   = shift;
    my $error_code = shift;

    if ( $ret_code == 0 ) {

        $logger->info(
            'Child process terminate successfully with return code = 0');

    }
    else {

        $logger->logdie( 'system failed to execute srvrmgr: ' . $error_code );

    }

}

# :TODO:18-10-2013:arfreitas: this should be done by IPC.pm module?
sub _check_system {

    my $self   = shift;
    my $logger = shift;
    weaken($logger);
    my $child_error = shift;
    my $ret_code    = shift;
    my $error_code  = shift;

    if ( $Config{osname} eq 'MSWin32' ) {

        $self->_manual_check( $logger, $ret_code, $error_code );

    }
    else {

      SWITCH: {

            if ( WIFEXITED($child_error) ) {

                $logger->info(
'Child process terminate with call to exit() with return code = '
                      . WEXITSTATUS($child_error) );
                last SWITCH;

            }

            if ( WIFSIGNALED($child_error) ) {

                $logger->logdie( 'Child process terminated due signal: '
                      . WTERMSIG($child_error) );
                last SWITCH;

            }

            if ( WIFSTOPPED($child_error) ) {

                $logger->logdie( 'Child process was stopped with '
                      . WSTOPSIG($child_error) );
                last SWITCH;

            }
            else {

                $self->_manual_check( $logger, $ret_code, $error_code );

            }

        }

        $self->_manual_check( $logger, $ret_code, $error_code );

    }

    return 1;

}

=pod

=head1 CAVEATS

This class is still considered experimental and should be used with care.

The C<srvrmgr> program uses buffering, which makes difficult to read the generated output as expected.

=head1 SEE ALSO

=over

=item *

L<Moose>

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

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>.

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
along with Siebel Monitoring Tools.  If not, see L<http://www.gnu.org/licenses/>.

=cut

__PACKAGE__->meta->make_immutable;

1;

