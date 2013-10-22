package Nagios::Plugin::Siebel::Srvrmgr::Exception::CacheFailure;
use Moose;
use namespace::autoclean;

extends 'Nagios::Plugin::Siebel::Srvrmgr::Exception';
has 'key' => (
    is     => 'ro',
    isa    => 'Str',
    reader => 'get_key',
	required => 1
);

has 'value' => (
    is     => 'ro',
    isa    => 'Str',
    reader => 'get_value',
	required => 1
);

sub BUILD {

    my $self = shift;

    $self->{error_msg} = 'Could not add key ' . $self->get_key() . ' to cache with value ' . $self->get_value();

}

__PACKAGE__->meta->make_immutable();

