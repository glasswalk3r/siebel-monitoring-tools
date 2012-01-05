package Siebel::Srvrmgr::ListParser::Output::ListComp::Server;
use Moose;
use namespace::autoclean;

has data =>
  ( isa => 'HashRef', is => 'ro', required => 1, reader => 'get_data' );

  has name => (isa => 'Str', is => 'ro',  required => 1, reader => 'get_name');

sub get_comps {

    my $self = shift;

    return [ keys( %{ $self->get_data() } ) ];

}

sub get_comp {

    my $self  = shift;
    my $alias = shift;

    if ( exists( $self->get_data()->{$alias} ) ) {

        return Siebel::Srvrmgr::ListParser::Output::ListComp::Comp->new(
            { data => $self->get_data()->{$alias}, alias => $alias } );

    }
    else {

        return undef;

    }

}

__PACKAGE__->meta->make_immutable;
