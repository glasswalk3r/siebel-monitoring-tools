package Test::Siebel::Srvrmgr::Action::CheckComps::Component;

use Moose;
use namespace::autoclean;

# this role demands to define the methods below
with 'Siebel::Srvrmgr::Daemon::Action::CheckComps::Component';

sub name {

	my $self = shift;

	return $self->{name};

}

sub description {

	my $self = shift;

	return $self->{description};

}

sub componentGroup {

	my $self = shift;

	return $self->{componentGroup};

}

sub OKStatus {

	my $self = shift;

	return $self->{OKStatus};

}

sub criticality {

	my $self = shift;

	return $self->{criticality};

}

__PACKAGE__->meta->make_immutable;
