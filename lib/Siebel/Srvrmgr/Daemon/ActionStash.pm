package Siebel::Srvrmgr::Daemon::ActionStash;

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon::ActionStash - singleton to stash data returned by Siebel::Srvrmgr::Daemon::Action subclasses

=head1 SYNOPSIS

package MyAction;
use Moose;
use namespace::autoclean;

extends 'Siebel::Srvrmgr::Daemon::Action';

	my $stash = Siebel::Srvrmgr::Daemon::ActionStash->initialize(
		{
			key1 => 'foobar', 
			key2 => 'foobar'
		}
	);

package main;

	my $stash = Siebel::Srvrmgr::Daemon::ActionStash->instance();

    # do something with the get_stash method

=head1 DESCRIPTION

blablablah.

=cut

use warnings;
use strict;
use MooseX::Singleton;
use MooseX::FollowPBP;

=pod

=head1 ATTRIBUTES

=head2 stash

This attribute is a reference to some data. This means that it will accept B<any> reference to some that structure that you think it will be useful.

=cut

has stash =>
  ( is => 'rw', isa => 'Ref', required => 0, default => sub { return [] } );

=pod

=head1 METHODS

=head2 get_stash

Returns the C<stash> attribute reference.

=head2 set_stash

Sets the C<stash> attribute. Expects a reference as parameter.

=head1 SEE ALSO

=over 2

=item *

L<Siebel::Srvrmgr::Daemon::Action>

=item *

L<MooseX::Singleton>

=back

=cut

1;
