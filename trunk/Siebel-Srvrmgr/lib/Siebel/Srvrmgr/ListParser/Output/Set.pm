package Siebel::Srvrmgr::ListParser::Output::Set;

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::LoadPreferences - subclass to parse load preferences command.

=cut

use Moose;
use namespace::autoclean;
use Carp;

extends 'Siebel::Srvrmgr::ListParser::Output';

=pod

=head1 SYNOPSIS

See L<Siebel::Srvrmgr::ListParser::Output> for example.

=head1 DESCRIPTION

This class is a subclass of L<Siebel::Srvrmgr::ListParser::Output>. In truth, this is not a parser for a C<list> command, but since the usage of
C<load preferences> is strongly recommended, this subclasses was added to enable usage in L<Siebel::Srvrmgr::Daemon::Action> subclasses.

=head1 ATTRIBUTES

=head1 METHODS

=head2 get_location

Returns the C<location> attribute.

=head2 set_location

Set the C<location> attribute. Expects and string as parameter.

=head2 parse

Parses the C<load preferences> output stored in the C<raw_data> attribute, setting the C<data_parsed> attribute.

The C<raw_data> attribute will be set to an reference to an empty array.

=cut

override 'parse' => sub {

    my $self = shift;

   # $self->set_data_parsed( \%parsed_lines );
    $self->set_raw_data( [] );

    return 1;

};

=pod

=head1 SEE ALSO

=over 2

=item *

L<Siebel::Srvrmgr::ListParser::Output>

=item *

L<Moose>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>.

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
along with Siebel Monitoring Tools.  If not, see L<http://www.gnu.org/licenses/>.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
