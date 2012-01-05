package Siebel::Srvrmgr::ListParser::Output::ListComp::Comp;
use Moose;
use namespace::autoclean;

has data =>
  ( isa => 'HashRef', is => 'ro', required => 1, reader => 'get_data' );

has alias => ( isa => 'Str', is => 'ro', required => 1, reader => 'get_alias' );

sub get_attribs {

    my $self = shift;

    return [ keys( %{ $self->get_data() } ) ];

}

sub get_attrib {

    my $self   = shift;
    my $attrib = shift;

    if ( exists( $self->get_data()->{$attrib} ) ) {

        return $self->get_data()->{$attrib};

    }
    else {

        return undef;

    }

}

sub create_cmd {

    my $self = shift;

    my $cmd =
        'create component definition '
      . $self->get_alias()
      . ' for component type '
      ;    # see "list comp types" and "list comp def", property
    #to define the comp type alias

	return $cmd;

}

__PACKAGE__->meta->make_immutable;
