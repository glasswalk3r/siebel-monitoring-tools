package Nagios::Plugin::Siebel::Srvrmgr::Exception::CompNotEqual;
use Moose;
use namespace::autoclean;

extends 'Nagios::Plugin::Siebel::Srvrmgr::Exception';

has expected =>
  ( is => 'ro', isa => 'Str', reader => 'get_expected', required => 1 );

has received =>
  ( is => 'ro', isa => 'Str', reader => 'get_received', required => 1 );

sub BUILD {

    my $self = shift;

    $self->{error_msg} = ' not equal to ';

}

override 'get_msg' => sub {

    my $self = shift;

    return
        $self->get_expected()
      . $self->get_error_msg()
      . $self->get_received();

};

__PACKAGE__->meta->make_immutable();

1;
