package Siebel::Lbconfig::Daemon::Action::AOM;
# VERSION
use Moose 2.0401;
use namespace::autoclean 0.13;
use Siebel::Srvrmgr::Daemon::ActionStash;
use Carp;
use Scalar::Util qw(blessed);

extends 'Siebel::Srvrmgr::Daemon::Action';

override '_build_exp_output' => sub {
    return 'Siebel::Srvrmgr::ListParser::Output::Tabular::ListComp';
};

override 'do_parsed' => sub {
    my ( $self, $obj ) = @_;
    my %comps;

    if ( $obj->isa( $self->get_exp_output ) ) {

        foreach my $servername ( @{ $obj->get_servers } ) {
            my $server = $obj->get_server($servername);

            foreach my $alias ( @{ $server->get_comps } ) {
                my $comp = $server->get_comp($alias);

                if (
                    ( $comp->get_run_mode eq 'Interactive' )
                    and (  ( $comp->get_ct_alias eq 'AppObjMgr' )
                        or ( $comp->get_ct_alias eq 'EAIObjMgr' ) )
                    and (  ( $comp->get_disp_run_state eq 'Online' )
                        or ( $comp->get_disp_run_state eq 'Running' ) )
                    and ( $comp->is_auto_start )
                  )
                {

                    if ( exists( $comps{$alias} ) ) {
                        push( @{ $comps{$alias} }, $servername );
                    }
                    else {
                        $comps{$alias} = [$servername];
                    }
                }
            }

        }

        foreach my $alias ( keys(%comps) ) {
            delete $comps{$alias} unless ( scalar( @{ $comps{$alias} } ) > 1 );
        }

        my $stash = Siebel::Srvrmgr::Daemon::ActionStash->instance();
        $stash->push_stash( \%comps );
        return 1;

    }
    else {
        confess('object received ISA not '
              . $self->get_exp_output() . ' but '
              . blessed($obj) );
    }

};

__PACKAGE__->meta->make_immutable;
