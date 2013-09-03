package Siebel::Srvrmgr::ListParser::Output::ListCompDef;

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::ListCompDef - subclass to parse component definitions

=cut

use Moose;
use namespace::autoclean;

extends 'Siebel::Srvrmgr::ListParser::Output';

=pod

=head1 SYNOPSIS

	use Siebel::Srvrmgr::ListParser::Output::ListCompDef;

	my $comp_defs = Siebel::Srvrmgr::ListParser::Output::ListCompDef->new({});

=head1 DESCRIPTION

This subclass of L<SiebeL::Srvrmgr::ListParser::Output> parses the output of the command C<list comp def COMPONENT_NAME>.

The order of the fields and their configuration must follow the pattern defined below:

	srvrmgr> configure list comp def
		CC_NAME (76):  Component name
		CT_NAME (76):  Component type name
		CC_RUNMODE (31):  Component run mode (enum)
		CC_ALIAS (31):  Component alias
		CC_DISP_ENABLE_ST (61):   Display enablement state (translatable)
		CC_DESC_TEXT (251):   Component description
		CG_NAME (76):  Component group
		CG_ALIAS (31):  Component Group Alias
		CC_INCARN_NO (23):  Incarnation Number

=head1 ATTRIBUTES

All attributes of L<SiebeL::Srvrmgr::ListParser::Output>.

=head1 METHODS

All methods of L<SiebeL::Srvrmgr::ListParser::Output> plus the ones explaned below.

=head2 get_comp_defs

Returns the content of C<comp_params> attribute.

=head2 set_comp_defs

Set the content of the C<comp_defs> attribute. Expects an array reference as parameter.

=head2 parse

Parses the content of C<raw_data> attribute, setting the result on C<parsed_data> attribute.

The contents of C<raw_data> is changed to an empty array reference at the end of the process.

It raises an exception when the parser is not able to define the C<fields_pattern> attribute.

=cut

sub _set_header_regex {

    return qr/^CC_NAME\s.*\sCC_INCARN_NO\s*$/;

}

=pod

=head2 _define_pattern

This method overrides the method from the parent class. The pattern is strict following the expected configuration from the "list comp def" command
from srvrmgr, as described in the DESCRIPTION.

=cut

override '_define_pattern' => sub {

    my $self = shift;
	# to make it easier for maintainence
    my @sizes = ( 76, 76, 31, 31, 61, 251, 76, 31, 23 );
    my $pattern;

# :WARNING   :09/05/2013 12:19:37:: + 2 because of the spaces after the "---" that will be trimmed, but this will cause problems
# with the split_fields method if col_seps is different from two space
    foreach (@sizes) {

        $pattern .= 'A' . ( $_ + 2 );

    }

    $self->_set_fields_pattern($pattern);

};

sub _parse_data {

    my $self       = shift;
    my $fields_ref = shift;
    my $parsed_ref = shift;

    my $cc_name = $fields_ref->[0];

    my $list_len = scalar( @{$fields_ref} );

    my $columns_ref = $self->get_header_cols();

    die "Cannot continue without defining fields names"
      unless ( defined($columns_ref) );

    if ( @{$fields_ref} ) {

        for ( my $i = 0 ; $i < $list_len ; $i++ ) {

            $parsed_ref->{$cc_name}->{ $columns_ref->[$i] } =
              $fields_ref->[$i];

        }

        return 1;

    }
    else {

        return 0;

    }

}

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
