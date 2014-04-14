package Siebel::Srvrmgr::ListParser::FSA;
use warnings;
use strict;
use Log::Log4perl;
use Siebel::Srvrmgr;
use Siebel::Srvrmgr::Regexes qw(SRVRMGR_PROMPT CONN_GREET);
use Scalar::Util qw(weaken);

use parent 'FSA::Rules';

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::FSA - the FSA::Rules class specification for Siebel::Srvrmgr::ListParser

=head1 SYNOPSIS

	use FSA::Rules;
	my $fsa = Siebel::Srvrmgr::ListParser::FSA->get_fsa();
    # do something with $fsa

    # for getting a diagram exported in your currently directory with a onliner
    perl -MSiebel::Srvrmgr::ListParser::FSA -e "Siebel::Srvrmgr::ListParser::FSA->export_diagram"

=head1 DESCRIPTION

Siebel::Srvrmgr::ListParser::FSA subclasses the state machine implemented by L<Siebel::Srvrmgr::ListParser> class.

This class also have a L<Log::Log4perl> instance built in the L<FSA::Rules> instance returned by L<get_fsa> method.

=head1 EXPORTS

Nothing.

=head1 METHODS

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

=head2 new

Returns the state machine object defined for usage with a L<Siebel::Srvrmgr::ListParser> instance.

=cut

sub new {

    my $class = shift;

    my $log_cfg = Siebel::Srvrmgr->logging_cfg();

    die 'Could not start logging facilities'
      unless ( Log::Log4perl->init_once( \$log_cfg ) );

    my $logger = Log::Log4perl->get_logger('Siebel::Srvrmgr::ListParser');

    weaken($logger);

    my $ls_params_regex =
      qr/list\sparams(\sfor\sserver\s\w+\sfor\scomponent\s\w+)?/;
    my $ls_tasks_regex =
      qr/list\stasks(\sfor\sserver\s\w+\scomponent\sgroup?\s\w+)?/;
    my $ls_servers_regex   = qr/list\sserver(s)?.*/;
    my $ls_comp_defs_regex = qr/list\scomp\sdefs?(\s\w+)?/;

    my %params = (
        done => sub {

            my $self = shift;

            my $curr_line = shift( @{ $self->notes('all_data') } );
            $self->notes( 'line_num' => ( $self->notes('line_num') + 1 ) );

            if ( defined($curr_line) ) {

                if ( defined( $self->notes('last_command') )
                    and ( $self->notes('last_command') eq 'exit' ) )
                {

                    return 1;

                }
                else {

                    $self->notes( line => $curr_line );
                    return 0;

                }

            }
            else {

                return 1;

            }

        }
    );

    my $self = $class->SUPER::new(
        \%params,
        no_data => {
            do => sub {

                if ( $logger->is_debug() ) {

                    $logger->debug('Searching for useful data');

                }

            },
            rules => [
                greetings => sub {

                    my $state = shift;

                    if ( defined( $state->notes('line') ) ) {

                        return ( $state->notes('line') =~ CONN_GREET );

                    }
                    else {

                        return 0;

                    }

                },
                command_submission => sub {

                    my $state = shift;

                    if ( defined( $state->notes('line') ) ) {

                        return ( $state->notes('line') =~ SRVRMGR_PROMPT );

                    }
                    else {

                        return 0;

                    }

                },
                no_data => sub { return 1 }
            ],
            message => 'Line read'

        },
        greetings => {
            label    => 'greetings message from srvrmgr',
            on_enter => sub {

                my $state = shift;
                $state->notes( is_cmd_changed     => 0 );
                $state->notes( is_data_wanted     => 1 );
                $state->notes( 'create_greetings' => 1 )
                  unless ( $state->notes('greetings_created') );
            },
            on_exit => sub {

                my $state = shift;
                $state->notes( is_data_wanted => 0 );

            },
            rules => [
                command_submission => sub {

                    my $state = shift;
                    return ( $state->notes('line') =~ SRVRMGR_PROMPT );

                },
                greetings => sub { return 1 }
            ],
            message => 'prompt found'
        },
        end => {
            do    => sub { $logger->debug('Enterprise says bye-bye') },
            rules => [
                no_data => sub {
                    return 1;
                  }
            ],
            message => 'EOF'
        },
        list_comp => {
            label    => 'parses output from a list comp command',
            on_enter => sub {
                my $state = shift;
                $state->notes( is_cmd_changed => 0 );
                $state->notes( is_data_wanted => 1 );
            },
            on_exit => sub {

                my $state = shift;
                $state->notes( is_data_wanted => 0 );

            },
            rules => [
                command_submission => sub {

                    my $state = shift;
                    return ( $state->notes('line') =~ SRVRMGR_PROMPT );

                },
                list_comp => sub { return 1; }
            ],
            message => 'prompt found'
        },
        list_comp_types => {
            label    => 'parses output from a list comp types command',
            on_enter => sub {
                my $state = shift;
                $state->notes( is_cmd_changed => 0 );
                $state->notes( is_data_wanted => 1 );
            },
            on_exit => sub {

                my $state = shift;
                $state->notes( is_data_wanted => 0 );

            },
            rules => [
                command_submission => sub {

                    my $state = shift;
                    return ( $state->notes('line') =~ SRVRMGR_PROMPT );

                },
                list_comp_types => sub { return 1; }
            ],
            message => 'prompt found'
        },
        list_params => {
            label    => 'parses output from a list params command',
            on_enter => sub {
                my $state = shift;
                $state->notes( is_cmd_changed => 0 );
                $state->notes( is_data_wanted => 1 );
            },
            on_exit => sub {

                my $state = shift;
                $state->notes( is_data_wanted => 0 );

            },
            rules => [
                command_submission => sub {

                    my $state = shift;
                    return ( $state->notes('line') =~ SRVRMGR_PROMPT );

                },
                list_params => sub { return 1; }
            ],
            message => 'prompt found'
        },
        list_comp_def => {
            label    => 'parses output from a list comp def command',
            on_enter => sub {
                my $state = shift;
                $state->notes( is_cmd_changed => 0 );
                $state->notes( is_data_wanted => 1 );
            },
            on_exit => sub {

                my $state = shift;
                $state->notes( is_data_wanted => 0 );

            },
            rules => [
                command_submission => sub {

                    my $state = shift;
                    return ( $state->notes('line') =~ SRVRMGR_PROMPT );

                },
                list_comp_def => sub { return 1; }
            ],
            message => 'prompt found'
        },
        list_tasks => {
            label    => 'parses output from a list tasks command',
            on_enter => sub {
                my $state = shift;
                $state->notes( is_cmd_changed => 0 );
                $state->notes( is_data_wanted => 1 );
            },
            on_exit => sub {

                my $state = shift;
                $state->notes( is_data_wanted => 0 );

            },
            rules => [
                command_submission => sub {

                    my $state = shift;
                    return ( $state->notes('line') =~ SRVRMGR_PROMPT );

                },
                list_tasks => sub { return 1; }
            ],
            message => 'prompt found'
        },
        list_servers => {
            label    => 'parses output from a list servers command',
            on_enter => sub {
                my $state = shift;
                $state->notes( is_cmd_changed => 0 );
                $state->notes( is_data_wanted => 1 );
            },
            on_exit => sub {

                my $state = shift;
                $state->notes( is_data_wanted => 0 );

            },
            rules => [
                command_submission => sub {

                    my $state = shift;
                    return ( $state->notes('line') =~ SRVRMGR_PROMPT );

                },
                list_servers => sub { return 1; }
            ],
            message => 'prompt found'
        },
        load_preferences => {
            label    => 'parses output from a load preferences command',
            on_enter => sub {
                my $state = shift;
                $state->notes( is_cmd_changed => 0 );
                $state->notes( is_data_wanted => 1 );
            },
            on_exit => sub {

                my $state = shift;
                $state->notes( is_data_wanted => 0 );

            },
            rules => [
                command_submission => sub {

                    my $state = shift;
                    return ( $state->notes('line') =~ SRVRMGR_PROMPT );

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

				$state->notes(found_prompt => 1);
                my $cmd = ( $state->notes('line') =~ SRVRMGR_PROMPT )[1];

                if ( ( defined($cmd) ) and ( $cmd ne '' ) ) {

                    # removing spaces from command
                    $cmd =~ s/^\s+//;
                    $cmd =~ s/\s+$//;

                    $logger->debug("last_command set with '$cmd'")
                      if $logger->is_debug();

                    $state->notes( last_command   => $cmd );
                    $state->notes( is_cmd_changed => 1 );

                }
                else {

                    if ( $logger->is_debug() ) {

                        $logger->debug(
                            'got prompt, but no command submitted in line '
                              . $state->notes('line_num') );

                    }

                    $state->notes( last_command   => '' );
                    $state->notes( is_cmd_changed => 1 );

                }

            },
            rules => [
                list_comp => sub {

                    my $state = shift;

                    if ( $state->notes('last_command') eq 'list comp' ) {

                        return 1;

                    }
                    else {

                        return 0;

                    }

                },
                list_comp_types => sub {

                    my $state = shift;

                    if ( ( $state->notes('last_command') eq 'list comp types' )
                        or
                        ( $state->notes('last_command') eq 'list comp type' ) )
                    {

                        return 1;

                    }
                    else {

                        return 0;

                    }

                },
                list_params => sub {

                    my $state = shift;

                    if ( $state->notes('last_command') =~ $ls_params_regex ) {

                        return 1;

                    }
                    else {

                        return 0;

                    }

                },
                list_tasks => sub {

                    my $state = shift;

                    if ( $state->notes('last_command') =~ $ls_tasks_regex ) {

                        return 1;

                    }
                    else {

                        return 0;

                    }

                },
                list_servers => sub {

                    my $state = shift;

                    if ( $state->notes('last_command') =~ $ls_servers_regex ) {

                        return 1;

                    }
                    else {

                        return 0;

                    }

                },
                list_comp_def => sub {

                    my $state = shift;

                    if ( $state->notes('last_command') =~ $ls_comp_defs_regex )
                    {

                        return 1;

                    }
                    else {

                        return 0;

                    }

                },
                load_preferences => sub {

                    my $state = shift;

                    if ( $state->notes('last_command') eq 'load preferences' ) {

                        return 1;

                    }
                    else {

                        return 0;

                    }

                },
                no_data => sub {

                    my $state = shift;

                    if ( $state->notes('last_command') eq '' ) {

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

    return $self;

}

=pod

=head2 free_refs

This methods eliminates all circular references that version 0.31 of L<FSA::Rules> has, which makes it impossible to call the C<DESTROY>
before the program termination.

It should be invoked before program termination, possibly also in C<DESTROY> and C<DEMOLISH> methods of objects to give to the Perl interpreter a change
to release memory by calling the related C<DESTROY> methods of L<FSA::Rules> and L<FSA::State> instances.

=cut

sub free_refs {

    my $self = shift;

    my $machines = \%FSA::Rules::machines;

    foreach my $state ( keys %{ $machines->{$self}->{table} } ) {

        $machines->{$self}->{table}->{$state} = undef;
        delete $machines->{$self}->{table}->{$state};

    }

    $self->{done} = undef;
    $machines->{$self}->{self} = undef;

    my $all_states = \%FSA::Rules::states;

    foreach my $state ( @{ $self->states } ) {

        $all_states->{$state}->{machine} = undef;
        delete $all_states->{$state}->{machine};

        for ( my $i = 0 ; $i <= $#{ $all_states->{$state}->{rules} } ; $i++ ) {

            $all_states->{$state}->{rules}->[$i]->{state} = undef;

        }

    }

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
