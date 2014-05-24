package Siebel::Srvrmgr::ListParser::Output::Tabular::ListServers;
use Moose;
use namespace::autoclean;

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::Tabular::ListServers - subclass to parse list servers command

=cut

extends 'Siebel::Srvrmgr::ListParser::Output::Tabular';

=pod

=head1 SYNOPSIS

See L<Siebel::Srvrmgr::ListParser::Output::Tabular> for examples.

=head1 DESCRIPTION

This subclass of L<Siebel::Srvrmgr::ListParser::Output::Tabular> parses the output of the command C<list servers>.

This class expectes the following order and configuration of fields from C<list servers> command:

    srvrmgr> configure list servers
        SBLSRVR_NAME (31):  Siebel Server name
        SBLSRVR_GROUP_NAME (46):  Siebel server Group name
        HOST_NAME (31):  Host name of server machine
        INSTALL_DIR (256):  Server install directory name
        SBLMGR_PID (16):  O/S process/thread ID of Siebel Server Manager
        SV_DISP_STATE (61):  Server state (started,  stopped,  etc.)
        SBLSRVR_STATE (31):  Server state internal (started,  stopped,  etc.)
        START_TIME (21):  Time the server was started
        END_TIME (21):  Time the server was stopped
        SBLSRVR_STATUS (101):  Server status

Anything different from that will generate exceptions when parsing

=head1 ATTRIBUTES

All from parent class.

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

=cut

sub _build_expected {

    my $self = shift;

    $self->_set_expected_fields(
        [
            'SBLSRVR_NAME',  'SBLSRVR_GROUP_NAME',
            'HOST_NAME',     'INSTALL_DIR',
            'SBLMGR_PID',    'SV_DISP_STATE',
            'SBLSRVR_STATE', 'START_TIME',
            'END_TIME',      'SBLSRVR_STATUS'
        ]
    );

}

=pod

=head2 get_lc_fields

Returns an array reference with all the expected fields names in lowercase.

=cut

sub get_lc_fields {

    my $self = shift;
    my @names;

    foreach ( @{ $self->get_expected_fields() } ) {

        push( @names, lc($_) );

    }

    return \@names;

}

sub _consume_data {

    my $self       = shift;
    my $fields_ref = shift;
    my $parsed_ref = shift;

    my $list_len    = scalar( @{$fields_ref} );
    my $server_name = $fields_ref->[0];

    my $columns_ref = $self->get_lc_fields();

    if ( @{$fields_ref} ) {

        for ( my $i = 1 ; $i < $list_len ; $i++ ) {

            $parsed_ref->{$server_name}->{ $columns_ref->[$i] } =
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

=over

=item *

L<Siebel::Srvrmgr::ListParser::Output::Tabular>

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

__PACKAGE__->meta->make_immutable;
1;
