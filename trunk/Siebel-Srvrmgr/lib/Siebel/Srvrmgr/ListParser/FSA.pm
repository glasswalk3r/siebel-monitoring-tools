package Siebel::Srvrmgr::ListParser::FSA;
use warnings;
use strict;
use FSA::Rules;
use Log::Log4perl;
use Siebel::Srvrmgr;

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::FSA - functions related to FSA::Rules defined for Siebel::Srvrmgr::ListParser

=head1 SYNOPSIS

	use FSA::Rules;
	my $fsa = Siebel::Srvrmgr::ListParser::FSA->get_fsa();
    # do something with $fsa

    # for getting a diagram exported in your currently directory with a onliner
    perl -MSiebel::Srvrmgr::ListParser::FSA -e "Siebel::Srvrmgr::ListParser::FSA->export_diagram"

=head1 DESCRIPTION

Siebel::Srvrmgr::ListParser::FSA implements the state machine used by L<Siebel::Srvrmgr::ListParser> class.

This class only have static methods and is considered to be experimental.

This class also have a L<Log::Log4perl> instance builtin the L<FSA::Rules> instance returned by L<get_fsa> method.

=head1 EXPORTS

Nothing.

=head1 STATIC METHODS

=head2 export_diagram

Creates a PNG file with the state machine diagram in the current directory where the method was invoked.

=cut

sub export_diagram {

    my $fsa = get_fsa();

    my $graph = $fsa->graph( layout => 'neato', overlap => 'false' );
    $graph->as_png('pretty.png');

    return 1;

}

=pod

=head2 get_fsa

Returns the state machine object defined for usage with a L<Siebel::Srvrmgr::ListParser> instance.

=cut

sub get_fsa {

    my $class = shift;

    my $log_cfg = Siebel::Srvrmgr->logging_cfg();

    die 'Could not start logging facilities'
      unless ( Log::Log4perl->init_once( \$log_cfg ) );

    my $logger = Log::Log4perl->get_logger('Siebel::Srvrmgr::ListParser');

    my $ls_params_regex =
      qr/list\sparams(\sfor\sserver\s\w+\sfor\scomponent\s\w+)?/;
    my $ls_tasks_regex =
      qr/list\stasks(\sfor\sserver\s\w+\scomponent\sgroup?\s\w+)?/;
    my $ls_servers_regex   = qr/list\sserver(s)?.*/;
    my $ls_comp_defs_regex = qr/list\scomp\sdefs?(\s\w+)?/;

    return FSA::Rules->new(
        no_data => {
            do => sub {
                $logger->debug('Searching for useful data');
            },
            rules => [
                greetings => sub {

                    my $state = shift;

                    return ( $state->notes('line') =~
                          $state->notes('parser')->get_hello_regex() );

                },
                command_submission => sub {

                    my $state = shift;

                    return ( $state->notes('line') =~
                          $state->notes('parser')->get_prompt_regex() );

                },
                no_data => sub { return 1 }
            ],
            message => 'Line read'

        },
        greetings => {
            do => sub {

                my $state = shift;

                if ( defined( $state->notes('line') ) ) {

                    $state->notes('parser')->set_buffer($state);
                }
            },
            rules => [
                command_submission => sub {

                    my $state = shift;

                    return ( $state->notes('line') =~
                          $state->notes('parser')->get_prompt_regex() );

                },
                greetings => sub { return 1 }
            ],
            message => 'prompt found'
        },
        end => {
            do    => sub { print "Enterprise says 'bye-bye'\n"; },
            rules => [
                no_data => sub {
                    return 1;
                  }
            ],
            message => 'EOF'
        },
        list_comp => {
            do => sub {
                my $state = shift;

                $state->notes('parser')->set_buffer($state);

            },
            on_exit => sub {
                my $state = shift;
                $state->notes('parser')->is_cmd_changed(0);
            },
            rules => [
                command_submission => sub {

                    my $state = shift;

                    return ( $state->notes('line') =~
                          $state->notes('parser')->get_prompt_regex() );

                },
                list_comp => sub { return 1; }
            ],
            message => 'prompt found'
        },
        list_comp_types => {
            do => sub {
                my $state = shift;

                $state->notes('parser')->set_buffer($state);

            },
            on_exit => sub {
                my $state = shift;
                $state->notes('parser')->is_cmd_changed(0);
            },
            rules => [
                command_submission => sub {

                    my $state = shift;

                    return ( $state->notes('line') =~
                          $state->notes('parser')->get_prompt_regex() );

                },
                list_comp_types => sub { return 1; }
            ],
            message => 'prompt found'
        },
        list_params => {
            do => sub {
                my $state = shift;

                $state->notes('parser')->set_buffer($state);

            },
            on_exit => sub {
                my $state = shift;
                $state->notes('parser')->is_cmd_changed(0);
            },
            rules => [
                command_submission => sub {

                    my $state = shift;

                    return ( $state->notes('line') =~
                          $state->notes('parser')->get_prompt_regex() );

                },
                list_params => sub { return 1; }
            ],
            message => 'prompt found'
        },
        list_comp_def => {
            do => sub {
                my $state = shift;

                $state->notes('parser')->set_buffer($state);

            },
            on_exit => sub {
                my $state = shift;
                $state->notes('parser')->is_cmd_changed(0);
            },
            rules => [
                command_submission => sub {

                    my $state = shift;

                    return ( $state->notes('line') =~
                          $state->notes('parser')->get_prompt_regex() );

                },
                list_comp_def => sub { return 1; }
            ],
            message => 'prompt found'
        },
        list_tasks => {
            do => sub {
                my $state = shift;

                $state->notes('parser')->set_buffer($state);

            },
            on_exit => sub {
                my $state = shift;
                $state->notes('parser')->is_cmd_changed(0);
            },
            rules => [
                command_submission => sub {

                    my $state = shift;

                    return ( $state->notes('line') =~
                          $state->notes('parser')->get_prompt_regex() );

                },
                list_tasks => sub { return 1; }
            ],
            message => 'prompt found'
        },
        list_servers => {
            do => sub {
                my $state = shift;

                $state->notes('parser')->set_buffer($state);

            },
            on_exit => sub {
                my $state = shift;
                $state->notes('parser')->is_cmd_changed(0);
            },
            rules => [
                command_submission => sub {

                    my $state = shift;

                    return ( $state->notes('line') =~
                          $state->notes('parser')->get_prompt_regex() );

                },
                list_servers => sub { return 1; }
            ],
            message => 'prompt found'
        },
        load_preferences => {
            do => sub {
                my $state = shift;

                $state->notes('parser')->set_buffer($state);

            },
            on_exit => sub {
                my $state = shift;
                $state->notes('parser')->is_cmd_changed(0);
            },
            rules => [
                command_submission => sub {

                    my $state = shift;

                    return ( $state->notes('line') =~
                          $state->notes('parser')->get_prompt_regex() );

                },
                load_preferences => sub { return 1; }
            ],
            message => 'prompt found'
        },
        command_submission => {
            do => sub {

                my $state = shift;

                if ( $logger->is_debug() ) {

                    $logger->debug( 'command_submission got ['
                          . $state->notes('line')
                          . ']' );

                }

                my $cmd =
                  ( $state->notes('line') =~
                      $state->notes('parser')->get_prompt_regex() )[1];

                if ( ( defined($cmd) ) and ( $cmd ne '' ) ) {

                    # removing spaces from command
                    $cmd =~ s/^\s+//;
                    $cmd =~ s/\s+$//;

                    $state->notes('parser')->set_last_command($cmd);
                }
                else {

                    if ( $logger->is_debug() ) {

                        $logger->debug(
                            'got prompt, but no command submitted in line '
                              . $state->notes('line_num') );

                    }
                    $state->notes('parser')->set_last_command('');

                }

            },
            rules => [
                list_comp => sub {

                    my $state = shift;

                    if ( $state->notes('parser')->get_last_command() eq
                        'list comp' )
                    {

                        return 1;

                    }
                    else {

                        return 0;

                    }

                },
                list_comp_types => sub {

                    my $state = shift;

                    if (
                        (
                            $state->notes('parser')->get_last_command() eq
                            'list comp types'
                        )
                        or ( $state->notes('parser')->get_last_command() eq
                            'list comp type' )
                      )
                    {

                        return 1;

                    }
                    else {

                        return 0;

                    }

                },
                list_params => sub {

                    my $state = shift;

                    if ( $state->notes('parser')->get_last_command() =~
                        $ls_params_regex )
                    {

                        return 1;

                    }
                    else {

                        return 0;

                    }

                },
                list_tasks => sub {

                    my $state = shift;

                    if ( $state->notes('parser')->get_last_command() =~
                        $ls_tasks_regex )
                    {

                        return 1;

                    }
                    else {

                        return 0;

                    }

                },
                list_servers => sub {

                    my $state = shift;

                    if ( $state->notes('parser')->get_last_command() =~
                        $ls_servers_regex )
                    {

                        return 1;

                    }
                    else {

                        return 0;

                    }

                },
                list_comp_def => sub {

                    my $state = shift;

                    if ( $state->notes('parser')->get_last_command() =~
                        $ls_comp_defs_regex )
                    {

                        return 1;

                    }
                    else {

                        return 0;

                    }

                },
                load_preferences => sub {

                    my $state = shift;

                    if ( $state->notes('parser')->get_last_command() eq
                        'load preferences' )
                    {

                        return 1;

                    }
                    else {

                        return 0;

                    }

                },
                no_data => sub {

                    my $state = shift;

                    if ( $state->notes('parser')->get_last_command() eq '' ) {

                        return 1;

                    }
                    else {

                        return 0;

                    }

                },

                # add other possibilities here of list commands
                command_submission =>
                  sub { return 1; }    # this must be the last item

            ],
            message => 'command submitted'
        }
    );

}

1;

=pod

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr::ListParser>

=item *

L<FSA::Rules>

=back

=head1 CAVEATS

This class has some problems, most due the API of L<FSA::Rules>: since the state machine is a group of references to subroutines, it holds references
to L<Siebel::Srvrmgr::ListParser>, which basically causes circular references between the two classes.

There is some workaround to the caused memory leaks due this configuration, but in future releases L<FSA::Rules> may be replaced to something else.

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>.

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
