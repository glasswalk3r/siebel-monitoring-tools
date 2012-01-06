package Siebel::Srvrmgr::Daemon::Action::ListComps;

=pod
=head1 NAME

Siebel::Srvrmgr::Daemon::Action - base class for Siebel::Srvrmgr::Daemon action

=head1 SYNOPSES

=cut

use Moose;
use namespace::autoclean;
use Storable qw(nstore);

extends 'Siebel::Srvrmgr::Daemon::Action';

has dump_file => ( isa => 'Str', is => 'rw' );

sub BUILD {

    my $self = shift;

    my $params_ref = $self->params();

    my $file = shift( @{$params_ref} );

    $self->dump_file($file) if ( defined($file) );

}

sub do {

    my $self   = shift;
    my $buffer = shift;    # array reference

    $self->get_parser()->parse($buffer);

    my $tree = $self->get_parser()->get_parsed_tree();

    my @comps
      ;   # array of Siebel::Srvrmgr::ListParser::Output::ListComp::Comp objects

    foreach my $obj ( @{$tree} ) {

        if ( $obj->isa('Siebel::Srvrmgr::ListParser::Output::ListComp') ) {

            my $servers_ref = $obj->get_servers();

            warn "Could not fetch servers\n"
              unless ( scalar( @{$servers_ref} ) > 0 );

            foreach my $servername ( @{$servers_ref} ) {

                my $server = $obj->get_server($servername);

                if ( defined($server) ) {

                    foreach my $comp_alias ( @{ $server->get_comps() } ) {

                        my $comp = $server->get_comp($comp_alias);

                        push( @comps, $comp );

                    }

                    last;

                }
                else {

                    warn "could not fetch $servername data\n";

                }

            }

            nstore \@comps, $self->dump_file();
            return 1;    # expecting only one type of output

        }

    }    # end of foreach block

	return 0;

}

__PACKAGE__->meta->make_immutable;