package Nagios::Plugin::Siebel::Srvrmgr::Action::Check;

use Moose;
use namespace::autoclean;
use Siebel::Srvrmgr::Daemon::ActionStash;
use Carp qw(confess);

extends 'Siebel::Srvrmgr::Daemon::Action';

override 'do' => sub {

    my $self   = shift;
    my $buffer = shift;    # array reference

    my $servers = $self->get_params();    # array reference

    super();

    my %servers;    # to locate the expected servers easier

    foreach my $server ( @{$servers} ) {

        $servers{ $server->get_name() } = $server;

    }

    $self->get_parser()->parse($buffer);

    my $tree = $self->get_parser()->get_parsed_tree();

    my %checked_comps;

    foreach my $obj ( @{$tree} ) {

        if ( $obj->isa('Siebel::Srvrmgr::ListParser::Output::ListComp') ) {

            my $servers_ref = $obj->get_servers();

            confess
"Could not fetch servers from the Siebel::Srvrmgr::ListParser::Output::ListComp object returned by the parser"
              unless ( scalar( @{$servers_ref} ) > 0 );

            foreach my $name ( @{$servers_ref} ) {

                my $server = $obj->get_server($name);

                if (
                    $server->isa(
                        'Siebel::Srvrmgr::ListParser::Output::ListComp::Server')
                  )
                {

                    my $name = $server->get_name();

                    if ( exists( $servers{$name} ) ) {

                        my $exp_srv =
                          $servers{$name};    # the expected server reference

                        foreach my $comp_alias (
                            keys( %{ $exp_srv->get_components() } ) )
                        {

                            my $exp_comp = $exp_srv->get_comp($comp_alias);

                            my $comp =
                              $server->get_comp( $exp_comp->get_alias() );

                            if ( defined($comp) ) {

                                my @valid_status =
                                  split( /\|/, $exp_comp->get_OKStatus() );

                                my $is_ok = 0;

                                foreach my $valid_status (@valid_status) {

                                    if ( $valid_status eq
                                        $comp->cp_disp_run_state() )
                                    {

                                        $is_ok = 1;
                                        last;

                                    }

                                }

                                if ($is_ok) {

                                    $checked_comps{ $exp_srv->get_name() }
                                      ->{ $exp_comp->get_alias() } = 1;

                                }
                                else {

                                    $checked_comps{ $exp_srv->get_name() }
                                      ->{ $exp_comp->get_alias() } = 0;

                                }

                            }
                            else {

                                confess
                                  'Could not find any component with name [',
                                  $exp_comp->get_alias() . ']';

                            }

                        }

                    }    # end of foreach comp
                    else {

                        confess 'Unexpected servername retrieved from buffer';

                    }

                }
                else {

                    confess "could not fetch $name data";

                }

            }    # end of foreach server

        }

    }    # end of foreach Siebel::Srvrmgr::ListParser::Output::ListComp object

    # found some servers
    if ( keys(%checked_comps) ) {

        my $stash = Siebel::Srvrmgr::Daemon::ActionStash->instance();

# :TODO      :24/07/2013 12:32:51:: it should set the stash with more than just the ok/not ok status from the components
        $stash->set_stash( [ \%checked_comps ] );

        return 1;

    }
    else {

        return 0;

    }

};

__PACKAGE__->meta->make_immutable;

1;
