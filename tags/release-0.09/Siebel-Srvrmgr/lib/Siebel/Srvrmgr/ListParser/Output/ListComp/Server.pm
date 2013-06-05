package Siebel::Srvrmgr::ListParser::Output::ListComp::Server;

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::ListComp::Server - class to parse and aggregate information about servers and their components

=cut

use Moose;
use MooseX::Storage;
use namespace::autoclean;
use Siebel::Srvrmgr::ListParser::Output::ListComp::Comp;
use Carp;

=pod

=head1 SYNOPSIS

    use Siebel::Srvrmgr::ListParser::Output::ListComp::Server;

	Siebel::Srvrmgr::ListParser::Output::ListComp::Server->new(
		{
			name => $servername,
			data => $list_comp_data->{$servername}
		}
	);

=head1 DESCRIPTION

This class represents a server in a Siebel Enterprise and it's related components. This class is meant to be instantied by a method from 
L<Siebel::Srvrmgr::ListParser::Output::ListComp> object.

This class inherits from L<MooseX::Storage>, using the L<MooseX::Storage::IO::StorableFile> trait. See the methods C<load> and C<store> for details.

=cut

with Storage( io => 'StorableFile' );

=head1 ATTRIBUTES

=head2 data

An hash reference with the original data used to create the object.

=cut

has data =>
  ( isa => 'HashRef', is => 'ro', required => 1, reader => 'get_data' );

=pod

=head2 name

A string with the name of the server.

=cut

has name => ( isa => 'Str', is => 'ro', required => 1, reader => 'get_name' );

=pod

=head1 METHODS

=head2 get_data

Returns an hash reference from the C<data> attribute.

=head2 get_name

Returns an string from the C<name> attribute.

=head2 load

Load the object data and methods from a previously serialized object.

Expects as a parameter a string the filename (or complete path).

=head2 store

Stores the object data and methods in a serialized file.

Expects as a parameter a string the filename (or complete path).

=head2 get_comps

Returns an array reference with all components alias available in the server.

=cut

sub get_comps {

    my $self = shift;

    return [ keys( %{ $self->get_data() } ) ];

}

=pod

=head2 get_comp

Expects an string with the component alias.

Returns a L<Siebel::Srvrmgr::ListParser::Output::ListComp::Comp> object if the component exists in the server, otherwise returns C<undef>.

=cut

sub get_comp {

    my $self  = shift;
    my $alias = shift;

    if ( exists( $self->get_data()->{$alias} ) ) {

        return Siebel::Srvrmgr::ListParser::Output::ListComp::Comp->new(
            { data => $self->get_data()->{$alias}, cc_alias => $alias } );

    }
    else {

        return undef;

    }

}

=pod

=head2 get_comp_data

Expects a string of component alias.

Returns a component data as a hash reference if the alias exists or C<undef> otherwise.

=cut

sub get_comp_data {

    my $self  = shift;
    my $alias = shift;

    confess 'Must give a valid value to alias parameter'
      unless ( defined($alias) );

    if ( exists( $self->get_data()->{$alias} ) ) {

        my $comp_ref = $self->get_data()->{$alias};
        $comp_ref->{CC_ALIAS} = $alias;

        return $comp_ref;

    }
    else {

        return undef;

    }

}

=pod

=head1 SEE ALSO

=over 4

=item *

L<Moose>

=item *

L<MooseX::Storage>

=item *

L<namespace::autoclean>

=item *

L<Siebel::Srvrmgr::ListParser::Output::ListComp::Comp>

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

__PACKAGE__->meta->make_immutable;
