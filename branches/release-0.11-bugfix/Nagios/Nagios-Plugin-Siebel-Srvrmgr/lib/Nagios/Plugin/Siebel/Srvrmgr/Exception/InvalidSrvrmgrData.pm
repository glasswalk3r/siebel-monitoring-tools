package Nagios::Plugin::Siebel::Srvrmgr::Exception::InvalidSrvrmgrData;
use Moose;
use namespace::autoclean;

extends 'Nagios::Plugin::Siebel::Srvrmgr::Exception';

sub BUILD {

    my $self = shift;

    $self->{error_msg} = 'Invalid data recovered from srvrmgr program';
}

__PACKAGE__->meta->make_immutable();

