package Siebel::Srvrmgr::Daemon::Action::CheckComps::Component;

use Moose::Role;

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon::Action::CheckComps::Component - role for classes that hold Siebel server components information

=head1 DESCRIPTION

This class is a role, not a subclass of L<Siebel::Srvrmgr::Daemon::Action::CheckComps>. It is intended to be used by classes that provides information
about which components are available in a Siebel server and which is their expected status.

=head1 ATTRIBUTES

=head2 name

A string representing the name of the component.

=cut

has name => ( isa => 'Str', is => 'ro', required => 1 );

=pod

=head2 description

A string representing the description of the component.

=cut

has description => ( isa => 'Str', is => 'ro', required => 1 );

=pod

=head2 componentGroup

A string representing the Component Group alias that this component is part of.

=cut

has componentGroup => ( isa => 'Str', is => 'ro', required => 1 );

=pod

=head2 OKStatus

The status that the component is expected to have. It may be one, several (concatenated with a pipe character) or none.

=cut

has OKStatus => ( isa => 'Str', is => 'ro', required => 1 );

=pod

=head2 criticality

A integer indicating how critical it is if the component does not have the expected status: the largest the number, the more critical it is.

=cut

has criticality => ( isa => 'Int', is => 'ro', required => 1 );

=pod

=head1 METHODS

One for each one of the attributes, with the same name for invocation. Those methods B<must> be overrided by the classes that applies this role or
an exception will be raised.

=cut

requires 'name';
requires 'description';
requires 'componentGroup';
requires 'OKStatus';
requires 'criticality';

=pod

=head1 SEE ALSO

=over 2

=item *

L<Siebel::Srvrmgr::Daemon::Action::CheckComps>

=item *

L<Siebel::Srvrmgr::Daemon::Action::CheckComps::Server>

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
