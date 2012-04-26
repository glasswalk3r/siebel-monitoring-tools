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

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.org<E<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.org<E<gt>

This file is part of Siebel Monitoring Tools.

Siebel Monitoring Tools is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel Monitoring Tools is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Siebel Monitoring Tools.  If not, see <http://www.gnu.org/licenses/>.

=cut

1;
