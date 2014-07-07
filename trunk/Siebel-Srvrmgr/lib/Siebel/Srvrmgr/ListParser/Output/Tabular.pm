package Siebel::Srvrmgr::ListParser::Output::Tabular;

use Moose;
use namespace::autoclean;
use Carp qw(cluck);
use Siebel::Srvrmgr::Regexes qw(ROWS_RETURNED);
use Siebel::Srvrmgr::Types;
use Siebel::Srvrmgr::ListParser::Output::Tabular::Struct::Fixed;
use Siebel::Srvrmgr::ListParser::Output::Tabular::Struct::Delimited;

extends 'Siebel::Srvrmgr::ListParser::Output';

has structure_type => (
    is       => 'ro',
    isa      => 'OutputTabularType',
    reader   => 'get_type',
    required => 1
);

has col_sep => (
    is     => 'ro',
    isa    => 'Chr',
    reader => 'get_col_sep'
);

has expected_fields => (
    is      => 'ro',
    isa     => 'ArrayRef',
    reader  => 'get_expected_fields',
    writer  => '_set_expected_fields',
    builder => '_build_expected',
    lazy    => 1
);

has known_types => (
    is      => 'ro',
    isa     => 'HashRef[Str]',
    reader  => 'get_known_types',
    default => sub {
        {
            fixed =>
              'Siebel::Srvrmgr::ListParser::Output::Tabular::Struct::Fixed',
            delimited =>
              'Siebel::Srvrmgr::ListParser::Output::Tabular::Struct::Delimited'
        };
    }
);

has found_header => (
    is      => 'ro',
    isa     => 'Bool',
    reader  => 'found_header',
    writer  => '_set_found_header',
    default => 0
);

sub _build_expected {

    confess
'_build_expected must be overrided by subclasses of Siebel::Srvrmgr::Output::Tabular';

}

sub _consume_data {

    confess
'_consume_data must be overrided by subclasses of Siebel::Srvrmgr::ListParser::Output::Tabular';

}

=pod

=head2 parse

The method that parses the content of C<raw_data> attribute.

This method expects a header in the file, so all subclasses of this class.

=cut

override 'parse' => sub {

    my $self = shift;

    my $data_ref = $self->get_raw_data();

    confess 'Invalid data to parse'
      unless ( ( ( ref($data_ref) ) eq 'ARRAY' )
        and ( scalar( @{$data_ref} ) ) );

# cleaning up, state machine should not handle the end of response from a list command
    while (
        ( scalar( @{$data_ref} ) > 0 )
        and (  ( $data_ref->[ $#{$data_ref} ] eq '' )
            or ( $data_ref->[ $#{$data_ref} ] =~ ROWS_RETURNED ) )
      )
    {

        pop( @{$data_ref} );

    }

    confess 'Raw data became invalid after initial cleanup'
      unless ( @{$data_ref} );

    my $struct;

  SWITCH: {

        if ( ( $self->get_type eq 'delimited' ) and $self->get_col_sep() ) {

            $struct = $self->get_known_types()->{ $self->get_type() }->new(
                {
                    header_cols => $self->get_expected_fields(),
                    col_sep     => $self->get_col_sep()
                }
            );

            last SWITCH;

        }

        if ( $self->get_type() eq 'fixed' ) {

            $struct = $self->get_known_types()->{ $self->get_type() }
              ->new( { header_cols => $self->get_expected_fields() } );

        }
        else {

            confess "Don't know what to do with "
              . $self->get_type()
              . ' and column separator = '
              . $self->get_col_sep();

        }

    }

    my $header       = $struct->get_header_regex();
    my $header_regex = qr/$header/;
    my %parsed_lines;
    my $line_header_regex = qr/^\-+\s/;

    foreach my $line ( @{$data_ref} ) {

      SWITCH: {

            if ( $line eq '' ) {

                # do nothing
                last SWITCH;
            }

            if ( $line =~ $line_header_regex )
            {    # this is the '-------' below the header

                confess 'could not defined fields pattern'
                  unless ( $struct->define_fields_pattern($line) );
                last SWITCH;

            }

            # this is the header
            if ( $line =~ $header_regex ) {

                $self->_set_found_header(1);
                last SWITCH;

            }
            else {

                my $fields_ref = $struct->get_fields($line);

                confess "Cannot continue without having fields pattern defined"
                  unless ( ( defined($fields_ref) ) and ( @{$fields_ref} ) );

                unless ( $self->_consume_data( $fields_ref, \%parsed_lines ) ) {

                    confess 'Could not parse fields from line [' . $line . ']';

                }

            }

        }

    }

    confess 'failure detected while parsing: header not found'
      unless ( $self->found_header() );

    $self->set_data_parsed( \%parsed_lines );
    $self->set_raw_data( [] );

    return 1;

};

=head1 CAVEATS

All subclasses of Siebel::Srvrmgr::ListParser::Output::Tabular expect to have both the header and trailer of executed commands in C<srvrmgr> program. Removing one or both 
of them will result in parsing errors and probably exceptions.

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr::ListParser::Output>

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

__PACKAGE__->meta->make_immutable;
1;
