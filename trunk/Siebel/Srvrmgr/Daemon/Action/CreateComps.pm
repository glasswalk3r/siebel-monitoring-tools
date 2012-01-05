package Siebel::Srvrmgr::Daemon::Action::CreateComps;

=pod
=head1 NAME

Siebel::Srvrmgr::Daemon::Action - base class for Siebel::Srvrmgr::Daemon action

=head1 SYNOPSES

=cut

use Moose;
use namespace::autoclean;
use Data::Dumper;

extends 'Siebel::Srvrmgr::Daemon::Action';

sub do {

    my $self   = shift;
    my $buffer = shift;    # array reference

    $self->get_parser()->parse($buffer);

    my $tree = $self->get_parser()->get_parsed_tree();

    foreach my $obj ( @{$tree} ) {

        if ( $obj->isa('Siebel::Srvrmgr::ListParser::Output::ListComp') ) {

			$obj->parse();

            my $servers_ref = $obj->get_servers();

            warn "Could not fetch servers\n"
              unless ( scalar( @{$servers_ref} ) > 0 );

            foreach my $servername ( @{$servers_ref} ) {

                my $server = $obj->get_server($servername);

                if ( defined($server) ) {

					foreach my $comp_alias(@{$server->get_comps()}) {

						$comp = $server->get_comp($comp_alias);

						return $comp->create_cmd();

					}

                } else {

					warn "could not fetch $servername data\n";

				}

            }

        }

    }

}

__PACKAGE__->meta->make_immutable;
