package Siebel::Srvrmgr::Daemon::Action::Serializable;

use Moose::Role;

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon::Action::Serializable - role for serializable subclasses of Siebel::Srvrmgr::Daemon::Action

=head1 DESCRIPTION

This class is a role, not a subclass of L<Siebel::Srvrmgr::Daemon::Action>. It is intended to be used by subclasses that
needs serialization to the filesystem.

=head1 ATTRIBUTES

=head2 dump_file

This attribute is a string used to indicate in which file the data from L<Siebel::Srvmrgr::ListParser::Output::ListCompDef> should
be serialized into the OS filesystem. The string can be a complete path or just the filename.

=cut

has dump_file => (
    isa    => 'Str',
    is     => 'rw',
    reader => 'get_dump_file',
    writer => 'set_dump_file'
);

=pod

=head1 METHODS

=head2 get_dump_file

Returns the string stored in the attribute C<dump_file>.

=head2 set_dump_file

Sets the attribute C<dump_file>. Expects a string as parameter.

=head2 BUILD

Right after object creation this method will process the C<params> attribute and retrieve the first index of the array reference
to define the C<dump_file> attribute using the method C<set_dump_file>.

If the C<params> attribute is an empty reference, the method wil raise an exception. If the value given is undefined or an empty
string, an exception will be raised as well.

=cut

sub BUILD {

    my $self = shift;

    my $params_ref = $self->get_params();

    unless ( ( defined($params_ref) ) and ( scalar( @{$params_ref} ) >= 1 ) ) {

        die
          'Must have at least one value in the params attribute array reference'

    }

    my $file = shift( @{$params_ref} );

    if ( ( defined($file) ) and ( $file ne '' ) ) {

        $self->set_dump_file($file) if ( defined($file) );

    }
    else {

        die 'dump_file attribute must be defined';

    }

}

=pod

=head1 SEE ALSO

L<Siebel::Srvrmgr::Daemon::Action>

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
