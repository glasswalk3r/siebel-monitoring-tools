package Siebel::Srvrmgr::OS::Process::Tasks_num;

use Moose;
use Scalar::Util::Numeric qw(isint);
use Carp qw(confess cluck);
use namespace::autoclean;

extends 'Siebel::Srvrmgr::OS::Process';

=pod

=head1 NAME

Siebel::Srvrmgr::OS::Process::Tasks_num - subclass of Siebel::Srvrmgr::OS::Process with additional number of tasks available

=head2 DESCRIPTION

This class holds information regarding a operational system process that is (hopefully) related to a running Siebel Server.

=head1 ATTRIBUTES

Additionally to all the parent class attributes, this class has the C<tasks_num> attribute.

=head2 tasks_num

A integer representing the number of tasks that Siebel Component has executing in determined moment.

This is read-write, non-required attribute with the default value of zero. For processes related to Siebel but not related to Siebel
Components, this is the expected value too.

=cut

has tasks_num => (
    is       => 'ro',
    isa      => 'Int',
    required => 0,
    default  => 0,
    reader   => 'get_tasks_num',
    writer   => '_set_tasks_num'
);

=head1 METHODS

=head2 get_tasks_num

Returns the value of the attribute C<tasks_num>.

=head2 set_tasks_num

Sets the value fo tasks related to this process.

Expects as parameter a positive integer.

The method will validate if the process being updated is related to a Siebel Component. If not, a warning will be raised and
no update will be made.

=cut

sub set_tasks_num {

    my ( $self, $value ) = @_;

    confess "set_tasks_num requires a positive integer as parameter"
      unless ( isint($value) );

    my $set = $self->_build_set();

    if ( $set->has( $self->get_fname ) ) {

        $self->_set_tasks_num($value);

    }
    else {

        cluck 'the process '
          . $self->get_fname()
          . ' is not a valid Siebel Server process';

    }

}

=head1 SEE ALSO

=over

=item *

L<Moose>

=item *

L<Siebel::Srvrmgr::OS::Process>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

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

__PACKAGE__->meta->make_immutable;
