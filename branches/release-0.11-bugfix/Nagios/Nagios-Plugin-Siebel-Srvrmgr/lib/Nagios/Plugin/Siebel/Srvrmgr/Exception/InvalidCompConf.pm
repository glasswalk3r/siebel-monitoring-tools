package Nagios::Plugin::Siebel::CheckComps::Exception::InvalidCompConf;
use Moose;
use namespace::autoclean;

extends 'Nagios::Plugin::Siebel::Srvrmgr::Exception';

sub BUILD {

    my $self = shift;

    $self->{error_msg} = 'Invalid component configuration in YAML file'

}

__PACKAGE__->meta->make_immutable();

