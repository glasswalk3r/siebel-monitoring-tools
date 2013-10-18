package Test::Siebel::Srvrmgr::Daemon::Action::CheckComps::Component;

use Moose;
use namespace::autoclean;

# this role demands to define the methods below
with 'Siebel::Srvrmgr::Daemon::Action::CheckComps::Component';

__PACKAGE__->meta->make_immutable;
