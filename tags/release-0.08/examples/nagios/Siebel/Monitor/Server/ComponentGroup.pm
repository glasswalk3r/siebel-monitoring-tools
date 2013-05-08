package Siebel::Monitor::Server::ComponentGroup;

use warnings;
use strict;
use XML::Rabbit;

has_xpath_value 'name'           => './@name';
has_xpath_value 'OKStatus'       => './@defaultOKStatus';

finalize_class();
