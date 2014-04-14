package Nagios::Plugin::Siebel::Srvrmgr::Exception::InvalidCompAlias;
use Moose;
use namespace::autoclean;

extends 'Nagios::Plugin::Siebel::Srvrmgr::Exception';

sub BUILD {

    my $self = shift;

    $self->{error_msg} = 'Invalid component alias';

}

__PACKAGE__->meta->make_immutable();

