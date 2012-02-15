package Siebel::Srvrmgr::ListParser::Output::ListCompTypes;
use Moose;

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::ListCompTypes - subclass to parse list comp types command

=cut

extends 'Siebel::Srvrmgr::ListParser::Output';

=pod

=head1 SYNOPSIS

See L<Siebel::Srvrmgr::ListParser::Output> for examples.

=head1 DESCRIPTION

This subclass of L<Siebel::Srvrmgr::ListParser::Output> parses the output of the command C<list comp types>.

This is the list configuration of the C<srvrmgr> expected by the module:

	srvrmgr> configure list comp type
		CT_NAME (76):  Component type name
		CT_RUNMODE (31):  Supported run mode
		CT_ALIAS (31):  Component type alias
		CT_DESC_TEXT (251):  Description of component type

If the configuration is not setup as this, the parsing will fail and the module may raise exceptions.

=head1 ATTRIBUTES

=head2 types_attribs

An array reference with all the component types attributes. Each index will be an hash reference with the fields CT_NAME, CT_RUNMODE, CT_ALIAS and CT_DESC_TEXT.

=cut

has 'types_attribs' => (
    is     => 'rw',
    isa    => 'ArrayRef',
    reader => 'get_attribs',
    writer => 'set_attribs'
);

=pod

=head1 METHODS

=head2 get_attribs

Returns the array reference stored in the C<types_attribs> attribute.

=head2 set_attribs

Sets the attribute C<types_attribs>. Expects an array reference as parameter.

=head2 parse

Parses the data stored in the C<raw_data> attribute, setting the C<parsed_lines> attribute.

The C<raw_data> will be set to a reference to an empty array at the end of the process.

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

            if ( $line =~ /^CT_NAME\s.*\sCT_DESC_TEXT(\s+)?$/ )
            {    # this is the header

                my @columns = split( /\s{2,}/, $line );

                $self->set_attribs( \@columns );

                last SWITCH;

            }
            else {

                my @fields_values;

                # :TODO:5/1/2012 16:33:37:: copy this check to the other parsers
                if ( defined( $self->get_fields_pattern() ) ) {

                    @fields_values =
                      unpack( $self->get_fields_pattern(), $line );

                }
                else {

                    die
                      "Cannot continue without having fields pattern defined\n";

                }

                my $ct_name = $fields_values[0];

                my $list_len = scalar(@fields_values);

                my $columns_ref = $self->get_attribs();

                if (@fields_values) {

                    for ( my $i = 0 ; $i < $list_len ; $i++ ) {

                        $parsed_lines{$ct_name}->{ $columns_ref->[$i] } =
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

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
