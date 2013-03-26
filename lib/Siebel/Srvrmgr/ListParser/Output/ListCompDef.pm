package Siebel::Srvrmgr::ListParser::Output::ListCompDef;

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::ListCompDef - subclass to parse component definitions

=cut

use Moose;

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

All attributes of L<SiebeL::Srvrmgr::ListParser::Output> plus the ones explaned below.

=head2 comp_params

An array reference with all the definitions of the component informed in the command C<list comp def>.

=cut

has 'comp_defs' => (
    is     => 'rw',
    isa    => 'ArrayRef',
    reader => 'get_comp_defs',
    writer => 'set_comp_defs'
);

=pod

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

sub parse {

    my $self = shift;

    my $data_ref = $self->get_raw_data();

    my %parsed_lines;

# removing the three last lines Siebel 7.5.3 (one blank line followed by a line amount of lines returned followed by a blank line)
    for ( 1 .. 3 ) {

        pop( @{$data_ref} );

    }

    foreach my $line ( @{$data_ref} ) {

        chomp($line);

      SWITCH: {

            if ( $line =~ /^\-+\s/ ) {    # this is the header line

                my @columns = split( /\s{2}/, $line );

                my $pattern;

                foreach my $column (@columns) {

                    $pattern .= 'A'
                      . ( length($column) + 2 )
                      ; # + 2 because of the spaces after the "---" that will be trimmed

                }

                $self->_set_fields_pattern($pattern);

                last SWITCH;

            }

            if ( $line eq '' ) {

                last SWITCH;

            }

            if ( $line =~ /^CC_NAME\s.*\sCC_INCARN_NO\s*$/ )
            {    # this is the header

                my @columns = split( /\s{2,}/, $line );

                $self->set_comp_defs( \@columns );

                last SWITCH;

            }
            else {

                my @fields_values;

                if ( $self->get_fields_pattern() ) {

                    @fields_values =
                      unpack( $self->get_fields_pattern(), $line );

                }
                else {

                    die
                      "Cannot continue since fields pattern was not defined\n";

                }

                my $cc_name = $fields_values[0];

                my $list_len = scalar(@fields_values);

                my $columns_ref = $self->get_comp_defs();

                confess "Cannot continue without defining fields names"
                  unless ( defined($columns_ref) );

                if (@fields_values) {

                    for ( my $i = 0 ; $i < $list_len ; $i++ ) {

                        $parsed_lines{$cc_name}->{ $columns_ref->[$i] } =
                          $fields_values[$i];

                    }

                }
                else {

                    warn "got nothing\n";

                }

            }

        }

    }

    $self->set_data_parsed( \%parsed_lines );
    $self->set_raw_data( [] );

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

no Moose;
__PACKAGE__->meta->make_immutable;
