package Siebel::Monitor::Server::Component;

use warnings;
use strict;
use XML::Rabbit;

has_xpath_value 'name'           => './@name';
has_xpath_value 'description'    => './@description';
has_xpath_value 'componentGroup' => './@ComponentGroup';
has_xpath_value 'OKStatus'       => './@OKStatus';
has_xpath_value 'criticality'    => './@criticality';

with 'Siebel::Srvrmgr::Daemon::Action::CheckComps::Component';

# this method exists to enable setting a OKStatus if the component is using the respective component group default
sub _set_ok_status {

    my $self  = shift;
    my $value = shift;

    my $meta = __PACKAGE__->meta();
    my $attr = $meta->get_attribute('OKStatus');
    $attr->set_value( $self, $value );

}

finalize_class();
