package Nagios::Plugin::Siebel::CheckComps::Action::Check::Component;
use Moose;
use namespace::autoclean;
use MooseX::FollowPBP;

with 'Siebel::Srvrmgr::Daemon::Action::CheckComps::Component';

has 'alias'          => ( is => 'rw', isa => 'Str', 'required' => 1 );
has 'description'    => ( is => 'rw', isa => 'Str', required   => 1 );
has 'componentGroup' => ( is => 'rw', isa => 'Str', required   => 1 );
has 'OKStatus'       => ( is => 'rw', isa => 'Str', required   => 1 );
has 'criticality'    => ( is => 'rw', isa => 'Str', required   => 1 );

# :TODO      :24/07/2013 12:34:02:: for future releases when the current status if available
#has 'currentStatus' => ( is => 'rw', isa => 'Str',  default => 'unknown' );
has 'isOK' => ( is => 'rw', isa => 'Bool', default => 0 );

__PACKAGE__->meta->make_immutable;

1;
