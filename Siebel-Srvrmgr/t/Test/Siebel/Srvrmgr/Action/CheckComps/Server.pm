package Test::Action::CheckComps::Server;

use Moose;
use namespace::autoclean;

with 'Siebel::Srvrmgr::Daemon::Action::CheckComps::Server';

sub name {

	my $self = shift;

	return $self->{name};

}

sub components {

	my $self = shift;

	return $self->{components};

}

__PACKAGE__->meta->make_immutable;
