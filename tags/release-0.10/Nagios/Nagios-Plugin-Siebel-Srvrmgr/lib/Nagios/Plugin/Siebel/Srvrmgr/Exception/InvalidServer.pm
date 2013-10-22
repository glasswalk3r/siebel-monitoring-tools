package Nagios::Plugin::Siebel::Srvrmgr::Exception::InvalidServer;
use Moose;
use namespace::autoclean;

extends 'Nagios::Plugin::Siebel::Srvrmgr::Exception';

sub BUILD {

    my $self = shift;

    $self->{error_msg} = 'The server does not exist in srvrmgr output: ';

}

has servername =>
  ( is => 'ro', isa => 'Str', reader => 'get_servername', required => 1 );

override 'get_msg' => sub {

    my $self       = shift;
    my $servername = shift;

    return $self->get_error_msg() . $self->get_servername();

};

__PACKAGE__->meta->make_immutable();

