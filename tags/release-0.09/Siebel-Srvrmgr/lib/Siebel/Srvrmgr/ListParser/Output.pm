package Siebel::Srvrmgr::ListParser::Output;

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output - base class of srvrmgr output

=head1 SYNOPSIS

	use Siebel::Srvrmgr::ListParser::Output;

	my $output = Siebel::Srvrmgr::ListParser::Output->new({ data_type => 'sometype', 
															raw_data => \@data, 
															cmd_line => 'list something from somewhere'});

	print 'Fields pattern: ', $output->get_fields_pattern(), "\n";
	$output->store($complete_pathname);

=cut

use Moose;

use MooseX::Storage;
use namespace::autoclean;
use Carp;
use feature qw(switch current_sub);

with Storage( io => 'StorableFile' );

=pod

=head1 DESCRIPTION

Siebel::Srvrmgr::ListParser::Output is a superclass of output types classes.

It contains only basic attributes and methods that enable specific parsing and serializable methods.

The C<parse> method must be overrided by subclasses or a exception will be raised during object creation.

=head1 ATTRIBUTES

=head2 data_type

Identifies which kind of data is being given to the class. This is usually used by abstract factory classes to identify which subclass of 
Siebel::Srvrmgr::ListParser::Output must be created.

This attribute is required during object creation.

=cut

has 'data_type' =>
  ( is => 'ro', isa => 'Str', reader => 'get_data_type', required => 1 );

=pod

=head2 raw_data

An array reference with the lines to be processed.

This attribute is required during object creation.

=cut

has 'raw_data' => (
    is       => 'rw',
    isa      => 'ArrayRef',
    reader   => 'get_raw_data',
    writer   => 'set_raw_data',
    required => 1

);

=pod

=head2 data_parsed

An hash reference with the data parsed from C<raw_data> attribute.

=cut

has 'data_parsed' => (
    is     => 'rw',
    isa    => 'HashRef',
    reader => 'get_data_parsed',
    writer => 'set_data_parsed'
);

=pod

=head2 cmd_line

A string of the command that originates the output (the data of C<raw_data> attribute).

This attribute is required during object creation.

=cut

has 'cmd_line' =>
  ( isa => 'Str', is => 'ro', reader => 'get_cmd_line', required => 1 );

=pod

=head2 fields_pattern

When starting processing the output of C<list comp> command, the header is read and the size of each column is taken
from the header of each column. With this information a pattern is build to match each value foreach line read. This 
attribute will hold the string that describes this pattern (that latter will be used with the C<unpack()> builtin function).

Therefore is B<really> important that the header of C<srvrmgr> program is not removed or the parser will not work properly
and probably an exception will be raised by it.

=cut

has 'fields_pattern' => (
    is      => 'ro',
    isa     => 'Str',
    reader  => 'get_fields_pattern',
    writer  => '_set_fields_pattern',
    default => sub { '' }
);

=pod

=head2 header_regex

The regular expression used to match the header of the list <command> output (the sequence of column names).
This is a regular expression reference as returned by C<qr> operator, which means that the regular expression is already optimized.

=cut

has 'header_regex' => (
    is      => 'ro',
    isa     => 'RegexpRef',
    builder => '_set_header_regex',
    reader  => 'get_header_regex',
    lazy    => 1
);

=pod

=head2 col_sep

The regular expression used to match the columns separator. Even thought the output has (or should have) a fixed size, the columns
are separated by a string.
This is a regular expression reference as returned by C<qr> operator, which means that the regular expression is already optimized.
col_sep has a builder C<sub> that can be override if the regular expression is different of C<\s{2,}>.

=cut

has 'col_sep' => (
    is      => 'ro',
    isa     => 'RegexpRef',
    builder => '_set_col_sep',
    reader  => 'get_col_sep',
    lazy    => 1
);

=head2 header_cols

An array reference with all the header columns names, in the exact sequence their appear in the output.

=cut

has 'header_cols' => (
    is     => 'rw',
    isa    => 'ArrayRef',
    reader => 'get_header_cols',
    writer => 'set_header_cols'
);

=pod

=head1 METHODS

=head2 get_fields_pattern

Returns an string of the attribute C<fields_pattern>.

=head2 get_cmd_line

Returns an string of the attribute C<get_cmd_line>.

=head2 get_data_parsed

Retuns an hash reference of C<data_parsed> attribute.

=head2 set_data_parsed

Sets the C<data_parsed> attribute. It is expected an hash reference as parameter of the method.

=head2 get_raw_data

Returns an array reference of the attribute C<raw_data>.

=head2 set_raw_data

Sets the C<raw_data> attribute. An array reference is expected as parameter of the method.

=head2 load

Method inherited from L<MooseX::Storage::IO::StorableFile> role. It loads a previously serialized Siebel::Srvrmgr::ListParser:Output object into memory.

=head2 store

Method inherited from L<MooseX::Storage::IO::StorableFile> role. It stores (serializes) a Siebel::Srvrmgr::ListParser:Output object into a file. A a string of the filename 
(with complete or not full path) is expected as a parameter.

=head2 BUILD

All subclasses of Siebel::Srvrmgr::ListParser::Object will call the method C<parse> right after object instatiation.

=cut

sub BUILD {

    my $self = shift;

    $self->parse();

}

=pod

=head2 parse

The method that actually does the parse of C<raw_data> attribute.

This method should be overrided by subclasses which output does not have a defined header, since this method expects to find a header
in the data to be parsed.

=cut

sub parse {

    my $self = shift;

    my $data_ref = $self->get_raw_data();

    my %parsed_lines;

    my $line_header_regex = qr/^\-+\s/;

# removing the three last lines (one blank line followed by a line amount of lines returned followed by a blank line)
    for ( 1 .. 3 ) {

        pop( @{$data_ref} );

    }

    foreach my $line ( @{$data_ref} ) {

        chomp($line);

        given ($line) {

            when ('') {

                # do nothing
            }

            when ($line_header_regex) { # this is the '-------' below the header

                my @columns = split( /\s{2}/, $line );

                my $pattern;

                foreach my $column (@columns) {

# :WARNING   :09/05/2013 12:19:37:: + 2 because of the spaces after the "---" that will be trimmed, but this will cause problems
# with the split_fields method if col_seps is different from two spaces
                    $pattern .= 'A' . ( length($column) + 2 );

                }

                $self->_set_fields_pattern($pattern);

            }

            # this is the header
            when ( $line =~ $self->get_header_regex() ) {

                $self->_set_header($line);

            }

            default {

                my @fields_values;

                # :TODO:5/1/2012 16:33:37:: copy this check to the other parsers
                if ( defined( $self->get_fields_pattern() ) ) {

                    @fields_values =
                      unpack( $self->get_fields_pattern(), $line );

                }
                else {

                    confess
                      "Cannot continue without having fields pattern defined";

                }

                unless ( $self->_parse_data( \@fields_values, \%parsed_lines ) )
                {

                    die 'Could not parse fields from line [' . $line . ']';

                }

            }

        }

    }

    $self->set_data_parsed( \%parsed_lines );
    $self->set_raw_data( [] );

}

=pod

=head2 _set_col_sep

This is a builder C<sub> to define C<col_sep> attribute. It is quite unlike it will be necessary to change that, but one can override it in subclasses
if needed.

This is a "private" method and should be used internally only.

=cut

sub _set_col_sep {

    return qr/\s{2,}/;

}

=pod

=head2 get_col_sep

Getter of C<col_sep> attribute.

=head2 _split_fields

Split a output line into fields as defined by C<get_col_sep> method. It expects a string as parameter.

Returns an array reference.

This is a "private" method and should be used internally only.

=cut

sub _split_fields {

    my $self = shift;
    my $line = shift;

    my @columns = split( $self->get_col_sep(), $line );

    return \@columns;

}

=pod

=head2 _set_header

Used to split and define the header fields (see attribute C<header_cols>).

This is a "private" method and should be used internally only but could be overrided by subclasses if it is necessary to change any field before setting
the C<header_cols> attribute.

It expects the header line as a parameter, setting the C<header_cols> attribute and returning true in the case of success.

=cut

sub _set_header {

    my $self = shift;
    my $line = shift;

    my $columns_ref = $self->_split_fields($line);

    $self->set_header_cols($columns_ref);

    return 1;

}

=pod

=head2 _parse_data

This method is responsible to parse the data from a list command output, after the header was parsed successfully.

This method must be overrided by subclasses since Siebel::Srvrmgr::Output doesn't know anything about how to parse it.

This method in "private" and should be used internally only (more specific, inside the C<parse> method).

The method expects the following parameters:

=over

=item fields 

An array reference with the fields recovered from the output of the list command.

=item parsed data

An hash reference with all the data already parsed by the C<parse> method.

=back

The method must return true or false depending on the result of parsing the fields and incrementing the parsed data as expected.

=cut

# :TODO      :08/05/2013 18:21:53:: should change this to a real method? Seems to be that almost all subclasses does the same
# process to parse their respective details besides header
sub _parse_data {

    die __SUB__ . ' method must be overrided by subclasses of ' . __PACKAGE__;

}

=pod

=head2 _set_header_regex

Expects no parameter. It sets the C<header_regex> attribute.

This method is the builder method of C<header_regex> attribute and must be overrided by subclasses of Siebel::Srvrmgr::ListParser::Output since the
superclass knows nothing about the format of the header from the list command output.

=cut

sub _set_header_regex {

    die __SUB__ . ' method must be overrided by subclasses of ' . __PACKAGE__;

}

=pod

=head1 CAVEATS

All subclasses of Siebel::Srvrmgr::ListParser::Output expect to have both the header and trailer of executed commands in C<srvrmgr> program. Removing one or both 
of them will result in parsing errors and probably exceptions.

=head1 SEE ALSO

=over 4 

=item *

L<Moose>

=item *

L<MooseX::Storage>

=item *

L<MooseX::Storage::IO::StorableFile>

=item *

L<namespace::autoclean>

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

