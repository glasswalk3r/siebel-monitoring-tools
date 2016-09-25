package Siebel::Lbconfig;
use strict;
use warnings;
use Siebel::Srvrmgr::Daemon::Light 0.26;
use Siebel::Srvrmgr::Daemon::Command 0.26;
use Set::Tiny 0.03;
use Siebel::Srvrmgr::Util::IniDaemon 0.26 qw(create_daemon);
use Config::IniFiles 2.88;
use Carp;
use Exporter 'import';
use Siebel::Lbconfig::Daemon::Action::ListServers;
use Siebel::Lbconfig::Daemon::Action::AOM;

# VERSION

=pod

=head1 NAME

Siebel::Lbconfig - helper to generate optimied lbconfig file

=head1 DESCRIPTION

The distribution Siebel-Lbconfig was created based on classes from L<Siebel::Srvrmgr>.

The command line utility C<lbconfig> will connect to a Siebel Enterprise with C<srvrmgr> and generate a optimized
lbconfig.txt file by search all active AOMs that take can take advantage of the native load balancer.

=cut

our @EXPORT_OK = qw(recover_info get_daemon);

=head1 FUNCTIONS

=head2 create_daemon

Creates a L<Siebel::Srvrmgr::Daemon> to connects to the Siebel Enterprise and retrieve the required information to create the lbconfig.txt.

It expects as parameters:

=over

=item *

A string of the complete path to a configuration file that is understandle by L<Config::Tiny> (a INI file).

=back

Check the section "Configuration file" of this Pod for details about how to create and maintain the INI file.

Return two values:

=over

=item *

The daemon instance

=item * 

A L<Siebel::Srvrmgr::Daemon::ActionStash> instance.

=back

=cut

sub get_daemon {
    my $cfg_file = shift;
    my $daemon   = create_daemon($cfg_file);

# LoadPreferences does not add anything into ActionStash, so it's ok use a second action here
    $daemon->push_command(
        Siebel::Srvrmgr::Daemon::Command->new(
            {
                command => 'list comp',
                action  => 'Siebel::Lbconfig::Daemon::Action::AOM'
            }
        )
    );

    $daemon->push_command(
        Siebel::Srvrmgr::Daemon::Command->new(
            {
                command => 'list servers',
                action  => 'Siebel::Lbconfig::Daemon::Action::ListServers'
            }
        )
    );
    my $stash = Siebel::Srvrmgr::Daemon::ActionStash->instance();
    return $daemon, $stash;
}

=head2 recover_info

Expects as parameter the L<Siebel::Srvrmgr::Daemon::ActionStash> instance returned by C<create_daemon> and
the Siebel Connection Broker TCP port.

Returns an array reference with all the rows data of the lbconfig.txt.

=cut

sub recover_info {
    my ( $stash, $scb_port ) = @_;
    my @data;
    my $comps_ref   = $stash->shift_stash();
    my $servers_ref = $stash->shift_stash();
    my $underscore  = qr/_/;
    my @sorted = sort(keys( %{$comps_ref} ));

    foreach my $comp_alias ( @sorted ) {
        my $virtual;

        if ( $comp_alias =~ $underscore ) {
            my @parts = split( '_', $comp_alias );
            $parts[0] =~ s/ObjMgr//;
            $virtual = $parts[0] . uc( $parts[1] ) . '_VS';
        }
        else {
            $virtual = $comp_alias . '_VS';
        }

        my @row;

        foreach my $server ( @{ $comps_ref->{$comp_alias} } ) {

            if (exists($servers_ref->{$server})) {
            push( @row,
                ( $servers_ref->{$server} . ':' . $server . ':' . $scb_port ) );
            } else {
                confess "'$server' is not part of the retrieved Sievel Server names!";
            }
        }

        push( @data, "$virtual=" . join( ';', @row ) . ';' );
    }

    return \@data;

}

=head1 CONFIGURATION FILE

The configuration file must have a INI format, which is supported by the L<Config::Tiny> module.

Here is an example of the required parameters with a description:

    [GENERAL]
    gateway=foobar:1055
    enterprise=MyEnterprise
    user=sadmin
    password=123456
    field_delimiter=|
    srvrmgr= /foobar/bin/srvrmgr
    load_prefs = 1
    type = light

Beware that the commands executed by C<lbconfig> requires that the output has a specific configuration set: setting
C<load_prefs> is not optional here, but a requirement!

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr>

=item *

L<Config::Tiny>

=item *

L<Siebel::Srvrmgr::Util::IniDaemon>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

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

1;
