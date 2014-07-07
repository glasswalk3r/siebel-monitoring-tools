package Siebel::Srvrmgr::ListParser::Output::Tabular::ListParams;
use Moose;
use namespace::autoclean;
use Carp;

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::Tabular::ListParams - subclass to parse output of the command C<list comp params>.

=cut

extends 'Siebel::Srvrmgr::ListParser::Output::Tabular';

=pod

=head1 SYNOPSIS

	use Siebel::Srvrmgr::ListParser::Output::Tabular::ListParams;

	my $comp_params = Siebel::Srvrmgr::ListParser::Output::Tabular::ListParams->new({ data_type => 'list_params', 
																			 raw_data => \@com_data, 
															                 cmd_line => 'list params for server XXXX component YYYY'});

	my $server_params = Siebel::Srvrmgr::ListParser::Output::Tabular::ListParams->new({ data_type => 'list_params', 
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
		PA:
		PA:
		PA:
		PA:
		PA_NAME (76):  Parameter name

The C<data_parsed> attribute will return the following data estructure:

	'data_parsed' => {
		'Parameter1' => {
			'PA_NAME' => 'Private key file name',
			'PA_DATATYPE' => 'String',
			'PA_SCOPE' => 'Subsystem',
			'PA_VALUE' => '', 
			'PA_1' => '',
			'PA_2' => '',
			'PA_3' => '',
			'PA_4' => '',
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
			'PA_1' => '',
			'PA_2' => '',
			'PA_3' => '',
			'PA_4' => '',
			'PA_ALIAS' => 'KeyFileName',
			'PA_SETLEVEL' => 'SIS_NEVER_SET',
			'PA_DISP_SETLEVEL' => 'SIS_NEVER_SET',
			'PA_SUBSYSTEM' => 'Networking'
			},
			# N parameters
	}

Beware that the fours fields named "PA" where renamed.

For this release there is no method implementation that would return a parameter name and it's properties, it's necessary to access the hashes directly.

=head1 ATTRIBUTES

Additionally to the parent class, these attributes are all generated from the command line given to new, if available.

Since they are set automatically, none is required. It is assumed that if a attribute is set to C<undef>, there are no corresponding options in the C<list parameter> command.

All these attributes are read-only.

=head2 server

An string representing the server from the command executed.

=cut

has server =>
  ( isa => 'Str', is => 'ro', writer => '_set_server', reader => 'get_server' );

=pod

=head2 comp_alias

An string of the component alias respective to the command executed.

=cut

has comp_alias => (
    isa    => 'Str',
    is     => 'ro',
    writer => '_set_comp_alias',
    reader => 'get_comp_alias'
);

=head2 named_subsys

A string representing the named subsystem used in the command.

=cut

has named_subsys => (
    isa    => 'Str',
    is     => 'ro',
    writer => '_set_named_subsys',
    reader => 'get_named_subsys'
);

=head2 task

A integer representing the task number used in the executed command.

=cut

has task =>
  ( isa => 'Int', is => 'ro', writer => '_set_task', reader => 'get_task' );

=head2 param

A string representing the specific parameter requested in the executed command.

=cut

has param =>
  ( isa => 'Str', is => 'ro', writer => '_set_param', reader => 'get_param' );

=pod

=head2 BUILD

Set values for some class attributes depending on the command line used during object creation.

=cut

sub BUILD {

    my $self = shift;

    if ( defined( $self->get_cmd_line() ) ) {

        my @tokens      = split( /\s/, $self->get_cmd_line );
        my $comp_regex  = qr/^comp(onent)?$/;
        my $param_regex = qr/param(eter)?s?/;

        while ( my $token = shift(@tokens) ) {

          SWITCH: {

                if ( $token =~ $comp_regex ) {

                    $self->_set_comp_alias( shift(@tokens) );
                    next;

                }

                if ( $token eq 'server' ) {

                    $self->_set_server( shift(@tokens) );
                    next;

                }

                if ( $token eq 'task' ) {

                    $self->_set_task( shift(@tokens) );
                    next;

                }

                if ( $token =~ $param_regex ) {

                    my $next = shift(@tokens);

                    next unless ( defined($next) );

                    if ( $next eq 'for' ) {

                        next;

                    }
                    else {

                        $self->_set_param($next);
                        next;

                    }

                }

                if ( $token eq 'named' ) {

                    shift(@tokens);    # remove the subsystem string
                    $self->_set_named_subsys( shift(@tokens) );
                    next;

                }

            }

        }

    }

}

sub _build_expected {

    my $self = shift;

    $self->_set_expected_fields(
        [
            'PA_ALIAS',         'PA_VALUE',
            'PA_DATATYPE',      'PA_SCOPE',
            'PA_SUBSYSTEM',     'PA_SETLEVEL',
            'PA_DISP_SETLEVEL', 'PA',
            'PA',               'PA',
            'PA',               'PA_NAME'
        ]
    );

}

sub _consume_data {

    my $self       = shift;
    my $fields_ref = shift;
    my $parsed_ref = shift;

    my $columns_ref = $self->get_expected_fields();

# :WORKAROUND:05-01-2014:: must give different names since the default storage is an hash
    $columns_ref->[7]  = 'PA_1';
    $columns_ref->[8]  = 'PA_2';
    $columns_ref->[9]  = 'PA_3';
    $columns_ref->[10] = 'PA_4';

    if ( @{$fields_ref} ) {

        my $pa_alias = $fields_ref->[0];
        my $list_len = scalar( @{$columns_ref} )
          ; # safer to use the columns reference size if the output has some issue

        for ( my $i = 1 ; $i < $list_len ; $i++ )
        {    # starting from 1 to skip the field PA_ALIAS

            $parsed_ref->{$pa_alias}->{ $columns_ref->[$i] } =
              $fields_ref->[$i];

        }

        return 1;

    }
    else {

        return 0;

    }

}

=pod

=head1 CAVEATS

On Win32 system the method C<load> inherited from the superclass is not recovering the related data of C<data_parsed> attribute, even when that data is saved with the C<store> method.

Despite that, the L<Storable> C<retrieve> function is capable to recover such data (but not the class methods).

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr::ListParser::Output::Tabular>

=item *

L<Moose>

=item *

L<Storable>

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
