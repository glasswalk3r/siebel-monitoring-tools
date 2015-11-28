package Siebel::Srvrmgr::Util::IniDaemon;

use strict;
use warnings;
use Siebel::Srvrmgr::Daemon::Heavy;
use Siebel::Srvrmgr::Daemon::Light;
use Siebel::Srvrmgr::Daemon::Command;
use Config::IniFiles 2.88;
use Exporter qw(import);
use Carp;

=pod

=head1 NAME

Siebel::Srvrmgr::Util::IniDaemon - creates a Siebel::Srvrmgr::Daemon from a INI configuration file

=head1 DESCRIPTION

This modules provides a interface to a Siebel Enterprise to search and extract parameters from a specific Siebel component from all Siebel Server it is available.

=head1 EXPORTS

The C<recover_info> function is the only one exported by default.

=cut

our @EXPORT_OK = qw(create_daemon);

=head1 FUNCTIONS

=head2 create_daemon

This functions connects to the Siebel Enterprise and retrieve the parameters values of the desired component.

It expects as parameters:

=over

=item *

A string of the complete path to a configuration file that is understandle by L<Config::IniFile>.

=back

=cut

sub create_daemon {

    my ($cfg_file) = @_;
    confess "$cfg_file does not exist or is not readable"
      unless ( ( -e $cfg_file ) and ( -r _ ) );
    my $cfg = Config::IniFiles->new( -file => $cfg_file );

    my @required =
      (qw(type gateway enterprise user password srvrmgr time_zone read_timeout));

    foreach my $param (@required) {
        confess "$param is missing in the $cfg_file"
          unless ( defined( $cfg->val( 'GENERAL', $param ) ) );
    }

    my $class;
    if ( $cfg->val( 'GENERAL', 'type' ) eq 'heavy' ) {
        $class = 'Siebel::Srvrmgr::Daemon::Heavy';
    }
    elsif ( $cfg->val( 'GENERAL', 'type' ) eq 'light' ) {
        $class = 'Siebel::Srvrmgr::Daemon::Light';
    }
    else {
        confess 'Invalid value "'
          . $cfg->val( 'GENERAL', 'type' )
          . '" for daemon type';
    }

    my $params = {
        gateway         => $cfg->val( 'GENERAL', 'gateway' ),
        enterprise      => $cfg->val( 'GENERAL', 'enterprise' ),
        user            => $cfg->val( 'GENERAL', 'user' ),
        password        => $cfg->val( 'GENERAL', 'password' ),
        field_delimiter => $cfg->val( 'GENERAL', 'field_delimiter' ),
        bin             => $cfg->val( 'GENERAL', 'srvrmgr' ),
        time_zone       => $cfg->val( 'GENERAL', 'time_zone' ),
        read_timeout    => $cfg->val( 'GENERAL', 'read_timeout' ),
    };

    if ( $cfg->val( 'GENERAL', 'load_prefs' ) ) {
        $params->{commands} = [
            Siebel::Srvrmgr::Daemon::Command->new(
                {
                    command => 'load preferences',
                    action  => 'LoadPreferences',
                }
            )
        ];
    }

    return $class->new($params);

}

=head1 CONFIGURATION FILE

The configuration file must have a INI format, which is supported by the L<Config::Tiny> module.

Here is an example of the required parameters with a description:

    [GENERAL]
    # the Siebel Gateway hostname and port, for example
    gateway=foobar:1055
    # the Siebel Enterprise name
    enterprise=MyEnterprise
    # the Siebel user with administrative privileges
    user=sadmin
    # the password from the user with administrative privileges
    password=123456
    # the field delimiter used to separate the output fields of srvrmgr
    field_delimiter=|
    # the complete pathname to the program srvrmgr
    srvrmgr= /foobar/bin/srvrmgr
    # if true, will add a "load preferences" command with "LoadPreferences" action automatically
    load_prefs = 1
    # type defines which subclass of Siebel::Srvrmgr::Daemon to use. The acceptable value is "heavy" 
    # for Siebel::Srvrmgr::Daemon::Heavy and "light" for Siebel::Srvrmgr::Daemon::Light
    type = heavy

Whatever other parameters or sections available on the same INI will be ignored.

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr>

=item *

L<Config::IniFile>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

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
