package Nagios::Plugin::Siebel::Srvrmgr::Exception::NotFoundCompAlias;
use Moose;
use namespace::autoclean;

extends 'Nagios::Plugin::Siebel::Srvrmgr::Exception';

sub BUILD {

    my $self = shift;

    $self->{error_msg} = 'Could not find the component alias ';

}

__PACKAGE__->meta->make_immutable();

