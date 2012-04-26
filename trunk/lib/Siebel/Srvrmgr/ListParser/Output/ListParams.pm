package Siebel::Srvrmgr::ListParser::Output::ListParams;
use Moose;
use namespace::autoclean;
use feature qw(switch);

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::ListParams - subclass to parse output of the command C<list comp params>.

=cut

extends 'Siebel::Srvrmgr::ListParser::Output';

=pod

=head1 SYNOPSIS

	use Siebel::Srvrmgr::ListParser::Output::ListParams;

	my $comp_params = Siebel::Srvrmgr::ListParser::Output::ListParams->new({ data_type => 'list_comp_params', 
																			 raw_data => \@com_data, 
															                 cmd_line => 'list params for server XXXX component YYYY'});

	my $server_params = Siebel::Srvrmgr::ListParser::Output::ListParams->new({ data_type => 'sometype', 
																			   raw_data => \@server_data,
															                   cmd_line => 'list params for server XXXX'});

=head1 DESCRIPTION

This module parses the output of the command C<list comp params>. Beware that those parameters may be of the server if a component alias is omitted from
the command line.

The parser expects to have the following configuration of fields for the respective command.

	srvrmgr> configure list params
		PA_ALIAS (31):  Parameter alias
		PA_VALUE (101):  Parameter value
		PA_DATATYPE (31):  Parameter value datatype
		PA_SCOPE (31):  Parameter level
		PA_SUBSYSTEM (31):  Parameter subsystem
		PA_SETLEVEL (31):  Internal level at which value was set
		PA_DISP_SETLEVEL (61):  Display level at which value was set (translatable)
		PA_NAME (76):  Parameter name

The C<data_parsed> attribute will return the following data estructure:

	'data_parsed' => {
		'Parameter1' => {
			'PA_NAME' => 'Private key file name',
			'PA_DATATYPE' => 'String',
			'PA_SCOPE' => 'Subsystem',
			'PA_VALUE' => '',
			'PA_ALIAS' => 'KeyFileName',
			'PA_SETLEVEL' => 'SIS_NEVER_SET',
			'PA_DISP_SETLEVEL' => 'SIS_NEVER_SET',
			'PA_SUBSYSTEM' => 'Networking'
			},
		'Parameter2' => {
			'PA_NAME' => 'Private key file name',
			'PA_DATATYPE' => 'String',
			'PA_SCOPE' => 'Subsystem',
			'PA_VALUE' => '',
			'PA_ALIAS' => 'KeyFileName',
			'PA_SETLEVEL' => 'SIS_NEVER_SET',
			'PA_DISP_SETLEVEL' => 'SIS_NEVER_SET',
			'PA_SUBSYSTEM' => 'Networking'
			},
			# N parameters
	}

Until now there is no method implementation that would return a parameter name and it's properties, it's necessary to access the hashes directly.

=head1 ATTRIBUTES

=head2 params

An array reference with the parameters attributes representing the output of the command C<list comp params>. If this description looks confusing, is the same
columns shown in the command C<configure list params>.

=cut

has 'params' => (
    is     => 'rw',
    isa    => 'ArrayRef',
    reader => 'get_params',
    writer => 'set_params'
);

=pod

=head2 server

An string representing the server from where the parameter were got.

=cut

has server =>
  ( isa => 'Str', is => 'ro', writer => '_set_server', reader => 'get_server' );

=pod

=head2 comp_alias

An string of the component alias respective to the command executed, if available (considering that the parameter may be of the server, not a component).

=cut

has comp_alias => (
    isa    => 'Str',
    is     => 'ro',
    writer => '_set_comp_alias',
    reader => 'get_comp_alias'
);

=pod

=head1 METHODS

=head2 get_params

Returns the attribute params.

=head2 set_params

Set the attribute params. Expects an array reference as parameter.

=head2 _set_details

A "private" method used to get the servername and component alias from the command line given as parameter during object creation.

=cut

sub _set_details {

    my $self = shift;

    if ( defined( $self->get_cmd_line() ) ) {

        given ( $self->get_cmd_line() ) {

            when ('list params') {
                $self->_set_server('connected server');
                $self->_set_comp_alias('N/A');
            }
            when (/^list\sparams\sfor\scomponent\s\w+$/) {
                $self->_set_server('connected server');
                $self->_set_comp_alias(
                    ( split( /\s/, $self->get_cmd_line() ) )[-1] );
            }
            when (/^list\sparams\sfor\sserver\s\w+$/) {
                $self->_set_server(
                    ( split( /\s/, $self->get_cmd_line() ) )[-1] );
                $self->_set_comp_alias('N/A');
            }
            when (/^list\sparams\sfor\sserver\s\w+\scomponent\s\w+$/) {

                my @values = split( /\s/, $self->get_cmd_line() );

                $self->_set_server( $values[4] );
                $self->_set_comp_alias( $values[6] );

            }

            default { die "got strange list params command: cannot parse"; }

        }

    }

}

=pod

=head2 BUILD

Execute the method C<_set_details> right after object creation.

=cut

sub BUILD {

    my $self = shift;

    $self->_set_details();

}

=pod

=head2 parse

Parses the data in the C<raw_data> attribute setting the C<data_parsed> at the end of process.

Beware that the C<raw_data> attribute will be set to an empty array reference at the end of the process.

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

            #SV_NAME     CC_ALIAS
            if ( $line =~ /^PA_ALIAS\s.*\sPA_NAME/ ) {    # this is the header

                my @columns = split( /\s{2,}/, $line );

                $self->set_params( \@columns );

                last SWITCH;

            }
            else {

                my @fields_values =
                  unpack( $self->get_fields_pattern(), $line );

                if (@fields_values) {

                    my $pa_alias    = $fields_values[0];
                    my $list_len    = scalar(@fields_values);
                    my $columns_ref = $self->get_params();

                    for ( my $i = 1 ; $i < $list_len ; $i++ )
                    {    # starting from 1 to skip the field PA_ALIAS

                        $parsed_lines{$pa_alias}->{ $columns_ref->[$i] } =
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

=head1 CAVEATS

On Win32 system the method C<load> inherited from the superclass is not recovering the related data of C<data_parsed> attribute, even when that data is saved with the C<store> method.

Despite that, the L<Storable> C<retrieve> function is capable to recover such data (but not the class methods).

=head1 SEE ALSO

=over 3

=item *

L<Siebel::Srvrmgr::ListParser::Output>

=item *

L<Moose>

=item *

L<Storable>

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
