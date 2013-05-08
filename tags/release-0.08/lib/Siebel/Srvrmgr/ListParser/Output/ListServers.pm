package Siebel::Srvrmgr::ListParser::Output::ListServers;
use Moose;
use namespace::autoclean;
use feature 'switch';

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::ListServers - subclass to parse list servers command

=cut

extends 'Siebel::Srvrmgr::ListParser::Output';

=pod

=head1 SYNOPSIS

See L<Siebel::Srvrmgr::ListParser::Output> for examples.

=head1 DESCRIPTION

This subclass of L<Siebel::Srvrmgr::ListParser::Output> parses the output of the command C<list servers>.

=head1 ATTRIBUTES

=head2 attribs

An array reference with the attributes of each Siebel Server listed by C<list servers> command.

=cut

has attribs => (
    is     => 'ro',
    isa    => 'ArrayRef',
    reader => 'get_attribs',
    writer => '_set_attribs'
);

=pod

=head1 METHODS

All methods from superclass plus some additional ones described below.

The hash reference returned by C<get_data_parsed> will look like that:

	siebfoobar' => HASH
	  'end_time' => ''
	  'host_name' => 'siebfoobar'
	  'install_dir' => '/app/siebel/siebsrvr'
	  'sblmgr_pid' => 20452
	  'sblsrvr_group_name' => ''
	  'sblsrvr_state' => 'Running'
	  'sblsrvr_status' => '8.1.1.7 [21238] LANG_INDEPENDENT'
	  'start_time' => '2013-04-22 15:32:25'
	  'sv_disp_state' => 'Running'

where the keys are the Siebel servers names, each one holding a reference to another hash with the keys shown above.

=head2 get_attribs

Returns the array reference stored in the C<types_attribs> attribute.

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

        given ($line) {

            when (/^\-+\s/) {    # this is the header line

                my @columns = split( /\s{2}/, $line );

                my $pattern;

                foreach my $column (@columns) {

                    $pattern .= 'A'
                      . ( length($column) + 2 )
                      ; # + 2 because of the spaces after the "---" that will be trimmed

                }

                $self->_set_fields_pattern($pattern);

            }

            when ('') { }    # do nothing

# SBLSRVR_NAME SBLSRVR_GROUP_NAME HOST_NAME INSTALL_DIR SBLMGR_PID SV_DISP_STATE SBLSRVR_STATE START_TIME END_TIME SBLSRVR_STATUS
            when (/^SBLSRVR_NAME\s.*\sSBLSRVR_STATUS(\s+)?$/)
            {                # this is the header

                my @columns = split( /\s{2,}/, lc($line) );

                $self->_set_attribs( \@columns );

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

                my $list_len    = scalar(@fields_values);
                my $server_name = $fields_values[0];

                my $columns_ref = $self->get_attribs();

                confess "Could not retrieve the name of the fields"
                  unless ( defined($columns_ref) );

                if (@fields_values) {

                    for ( my $i = 1 ; $i < $list_len ; $i++ ) {

                        $parsed_lines{$server_name}->{ $columns_ref->[$i] } =
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

__PACKAGE__->meta->make_immutable;
1;
