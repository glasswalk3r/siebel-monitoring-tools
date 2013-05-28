package Siebel::Srvrmgr::ListParser::FSA;
use warnings;
use strict;
use FSA::Rules;

sub get_fsa {

    my $class  = shift;
    my $logger = shift;

    my $ls_params_regex =
      qr/list\sparams(\sfor\sserver\s\w+\sfor\scomponent\s\w+)?/;
    my $ls_tasks_regex =
      qr/list\stasks(\sfor\sserver\s\w+\scomponent\sgroup?\s\w+)?/;
    my $ls_servers_regex   = qr/list\sserver(s)?.*/;
    my $ls_comp_defs_regex = qr/list\scomp\sdefs?(\s\w+)?/;

    my $fsa = FSA::Rules->new(
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

    return $fsa;

}

1;

__END__

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::FSA - creates an instance of a FSA::Rules classes with definitions for Siebel::Srvrmgr::ListParser

=head1 DESCRIPTION

This package was created only to remove code expecific of L<FSA::Rules> to another package to easy debugging, so it's not intended to be used outside
the scope of C<parse> method from L<Siebel::Srvrmgr::ListParser> class.

=head1 CLASS METHODS

=head2 get_fsa

Expects as a parameter a L<Log::Log4perl> object.

Returns a L<FSA::Rules> object with definitions as required by L<Siebel::Srvrmgr::ListParser> class.

=head1 EXPORTS

Nothing. But see C<get_fsa> class method.

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr::ListParser>

=item *

L<FSA::Rules>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.org<E<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.org<E<gt>

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
