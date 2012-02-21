package Siebel::Srvrmgr::Daemon::ActionFactory;

use warnings;
use strict;
use MooseX::AbstractFactory;

implementation_class_via sub { 'Siebel::Srvrmgr::Daemon::Action::' . shift };

1;
