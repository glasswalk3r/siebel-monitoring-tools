package Nagios::Plugin::Siebel::Srvrmgr::Exception;
use Moose;
use namespace::autoclean;

has error_code => ( is => 'ro', isa => 'Int', reader => 'get_error_code' );

has error_msg => (
    is     => 'ro',
    isa    => 'Str',
    reader => 'get_error_msg'
);

sub get_name {

    my $self = shift;

    return $self->meta()->name();

}

sub get_msg {

    my $self = shift;

    return $self->get_error_msg;

}

__PACKAGE__->meta()->make_immutable();

