package Nagios::Plugin::Siebel::CheckComps::Action::Check::Server;
use Moose;
use namespace::autoclean;
use MooseX::FollowPBP;

with 'Siebel::Srvrmgr::Daemon::Action::CheckComps::Server';

has 'name' => ( is => 'rw', isa => 'Str', required => 1 );

has 'comps_by_name' => (
    is => 'rw',
    isa =>
      'HashRef[Nagios::Plugin::Siebel::CheckComps::Action::Check::Component]',
);

sub BUILD {

    my $self = shift;

    foreach my $comp ( @{ $self->components() } ) {

        $self->{comps_by_name}->{ $comp->name() } = $comp;

    }

}

sub add_comp {

    my $self = shift;
    my $comp = shift;

    unless ( $self->has_comp( $comp->get_alias() ) ) {

        $self->get_components()->{ $comp->get_alias() } = $comp;
        return 1;

    }
    else {

        return 0;

    }

}

sub has_comp {

    my $self       = shift;
    my $comp_alias = shift;

    return ( exists( $self->get_comps_by_name()->{$comp_alias} ) );

}

sub get_comp_by_name {

    my $self       = shift;
    my $comp_alias = shift;

    return $self->get_comps_by_name()->{$comp_alias};

}

__PACKAGE__->meta->make_immutable;

1;
