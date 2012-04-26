package Siebel::Srvrmgr::ListParser::Output::ListComp;

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::Listcomp - subclass that parses C<list comp> commands output of srvrmgr.

=cut

use Moose;
use namespace::autoclean;
use Siebel::Srvrmgr::ListParser::Output::ListComp::Server;
use Siebel::Srvrmgr::ListParser::Output::ListComp::Comp;

=head1 SYNOPSIS

See L<Siebel::Srvrmgr::ListParser::Output>.

=cut

extends 'Siebel::Srvrmgr::ListParser::Output';

=pod

=head1 DESCRIPTION

This class extends L<Siebel::Srvrmgr::ListParser::Output> base class adding support for parsing C<list comp> commands.

The module is capable of identifying output of several servers configured in the enterprise and organizes the components
found for each server.

It is expected that the C<srvrmgr> program has a proper configuration for the C<list comp> command. The configuration
can see below:

	srvrmgr> configure list comp
		SV_NAME (31):  Server name
		CC_ALIAS (31):  Component alias
		CC_NAME (76):  Component name
		CT_ALIAS (31):  Component type alias
		CG_ALIAS (31):  Component GRoup Alias
		CC_RUNMODE (31):  Component run mode (enum)
		CP_DISP_RUN_STATE (61):  Component display run state
		CP_NUM_RUN_TASKS (11):  Current number of running tasks
		CP_MAX_TASKS (11):  Maximum tasks configured
		CP_ACTV_MTS_PROCS (11):  Active MTS control processes
		CP_MAX_MTS_PROCS (11):  Maximum MTS control processes
		CP_START_TIME (21):  Component start time
		CP_END_TIME (21):  Component end time
		CP_STATUS (251):  Component-reported status
		CC_INCARN_NO (23):  Incarnation Number
		CC_DESC_TEXT (251):  Component description

This output above should be the default but it will be necessary to have the configuration below
(check the difference of size for each column):

	srvrmgr> configure list comp
		SV_NAME (31):  Server name
		CC_ALIAS (31):  Component alias
		CC_NAME (76):  Component name
		CT_ALIAS (31):  Component type alias
		CG_ALIAS (31):  Component GRoup Alias
		CC_RUNMODE (31):  Component run mode (enum)
		CP_DISP_RUN_STATE (61):  Component display run state
		CP_NUM_RUN_TASKS (16):  Current number of running tasks
		CP_MAX_TASKS (12):  Maximum tasks configured
		CP_ACTV_MTS_PROCS (17):  Active MTS control processes
		CP_MAX_MTS_PROCS (16):  Maximum MTS control processes
		CP_START_TIME (21):  Component start time
		CP_END_TIME (21):  Component end time
		CP_STATUS (251):  Component-reported status
		CC_INCARN_NO (23):  Incarnation Number
		CC_DESC_TEXT (251):  Component description

because L<Siebel::Srvrmgr::ListParser::Output::ListComp::Comp> will expect to have all columns names without being 
truncated. This class will check those columns names and order and it will raise an exception if it found something different
from the expected.

To enable that, execute the following commands in the C<srvrmgr> program:

	set ColumnWidth true

	configure list comp show SV_NAME(31), CC_ALIAS(21), CC_NAME(31), CG_ALIAS(31), CC_RUNMODE(31), CP_DISP_RUN_STATE(61),\
	CP_NUM_RUN_TASKS(16), CP_MAX_TASKS(11), CP_ACTV_MTS_PROCS(17), CP_MAX_MTS_PROCS(16), CP_START_TIME(21), \
	CP_END_TIME(21), CP_STATUS(251), CC_INCARN_NO(23), CC_DESC_TEXT(251)

Saving this configuration as a preference and loading it everytime is a good idea too.

=head1 ATTRIBUTES

=head2 last_server

A string that represents the last associated server from the list of components read from output.

By default, the value of it is an empty string.

This attribute is used during parsing of C<list comp> command and is a read-only attribute.

=cut

has 'last_server' => (
    is      => 'ro',
    isa     => 'Str',
    reader  => 'get_last_server',
    writer  => '__set_last_server',
    default => ''
);

=pod

=head2 comp_attribs

An array reference with the components attributes. This is a read-only attribute.

=cut

has 'comp_attribs' => (
    is     => 'ro',
    isa    => 'ArrayRef',
    reader => 'get_comp_attribs',
    writer => '__set_comp_attribs',
);

=pod

=head2 servers

This is an array reference with the servers found during processing of the C<list components> output.

=cut

has 'servers' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    reader  => 'get_servers',
    default => sub { return [] }
);

=pod

=head1 METHODS

=cut

sub _set_comp_attribs {

    my $self = shift;
    my $data = shift;

    my @expected_attribs = (
        'CC_NAME',           'CT_ALIAS',
        'CG_ALIAS',          'CC_RUNMODE',
        'CP_DISP_RUN_STATE', 'CP_NUM_RUN_TASKS',
        'CP_MAX_TASKS',      'CP_ACTV_MTS_PROCS',
        'CP_MAX_MTS_PROCS',  'CP_START_TIME',
        'CP_END_TIME',       'CP_STATUS',
        'CC_INCARN_NO',      'CC_DESC_TEXT'
    );

    for ( my $i = 0 ; $i <= $#expected_attribs ; $i++ ) {

        unless ( $data->[$i] eq $expected_attribs[$i] ) {

            die 'invalid attribute name recovered from output: expected '
              . $expected_attribs[$i]
              . ', got '
              . $data->[$i];

        }

    }

    $self->__set_comp_attribs($data);

}

=head2 get_fields_pattern

Returns the field_pattern attribute as a string.

=head2 get_comp_attribs

Returns the value of comp_attribs attribute as an array reference.

=head2 get_last_server

Returns the last_server attribute as a string.

=head2 get_servers

Returns the value of servers attribute as an array reference.

=head2 get_server

Expects as parameter the name of a server which output was parsed. 

If the server exists in the C<servers> attribute, it returns a L<Siebel::Srvrmgr::ListParser::Output::ListComp::Server> 
object. Otherwise it will return C<undef>.

=cut

sub get_server {

    my $self       = shift;
    my $servername = shift;

    if ( exists( $self->get_data_parsed()->{$servername} ) ) {

        return Siebel::Srvrmgr::ListParser::Output::ListComp::Server->new(
            {
                name => $servername,
                data => $self->get_data_parsed()->{$servername}
            }
        );

    }
    else {

        return undef;

    }

}

sub _set_last_server {

    my $self   = shift;
    my $server = shift;

    $self->__set_last_server($server);
    push( @{ $self->get_servers() }, $server );

}

=pod

=head2 parse

Parsers the data available in the C<raw_data> attribute, populating the C<data_parsed> attribute.

The C<raw_data> attribute will be set to an empty array reference once the parsing is finished.

=cut

sub parse {

    my $self = shift;

    my $data_ref = $self->get_raw_data();

    my %parsed_lines;

    # removing the three last lines Siebel 7.5.3
    for ( 1 .. 3 ) {

        pop( @{$data_ref} );

    }

    foreach my $line ( @{$data_ref} ) {

        chomp($line);

      SWITCH: {

            if ( $line =~ /^\-+\s/ ) {

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
            if ( $line =~ /^SV_NAME\s+CC_ALIAS/ ) {

                my @columns = split( /\s{2,}/, $line );

                #SV_NAME is usuless here
                shift(@columns);

                # component alias do not need to be maintained here
                shift(@columns);

                $self->_set_comp_attribs( \@columns );

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

                my $server = shift(@fields_values);

                # do not need the servername again
                if (   ( $self->get_last_server() eq '' )
                    or ( $self->get_last_server() ne $server ) )
                {

                    $self->_set_last_server($server);

                }

                my $comp_alias = shift(@fields_values);

                my $list_len = scalar(@fields_values);

                my $columns_ref = $self->get_comp_attribs();

                if (@fields_values) {

                    for ( my $i = 0 ; $i < $list_len ; $i++ ) {

                        my $server = $self->get_last_server();

                        $parsed_lines{$server}->{$comp_alias}
                          ->{ $columns_ref->[$i] } = $fields_values[$i];

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

=over 4 

=item *

L<Moose>

=item *

L<namespace::autoclean>

=item *

L<Siebel::Srvrmgr::ListParser::Output::ListComp::Server>

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

no Moose;
__PACKAGE__->meta->make_immutable;

