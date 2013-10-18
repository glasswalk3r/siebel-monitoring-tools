package Nagios::Plugin::Siebel::Srvrmgr::Exception::CacheFailure;
use Moose;
use namespace::autoclean;

extends 'Nagios::Plugin::Siebel::Srvrmgr::Exception';

sub BUILD {

    my $self = shift;

    $self->{error_msg} = 'Could not add key to cache';

}

__PACKAGE__->meta->make_immutable();

