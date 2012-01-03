package Siebel::Srvrmgr::Daemon::Action::Dumper;

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

    my $self = shift;
	my $buffer= shift; # array reference

	print Dumper($buffer);

}

__PACKAGE__->meta->make_immutable;
