package Siebel::Monitor::Server;

use warnings;
use strict;
use XML::Rabbit;

has_xpath_value 'name'             => './@name';
has_xpath_object_list 'components' => './ns1:components/ns1:component' =>
  'Siebel::Monitor::Server::Component';

has_xpath_object_list 'componentGroups' =>
  './ns1:componentsGroups/ns1:componentGroup' =>
  'Siebel::Monitor::Server::ComponentGroup';

with 'Siebel::Srvrmgr::Daemon::Action::CheckComps::Server';

finalize_class();
