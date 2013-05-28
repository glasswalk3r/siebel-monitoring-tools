use warnings;
use strict;
use Siebel::Srvrmgr::Daemon;
use File::Spec::Functions qw(tmpdir catfile);
use Nagios::Plugin;
use Siebel::Srvrmgr::Daemon::ActionStash;
use lib '.';
use Siebel::Monitor::Config;

#    COPYRIGHT AND LICENCE
#
#    This software is copyright (c) 2012 of Alceu Rodrigues de Freitas Junior, arfreitas@cpan.org
#
#    This file is part of Siebel Monitoring Tools.
#
#    Siebel Monitoring Tools is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    Siebel Monitoring Tools is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with Siebel Monitoring Tools.  If not, see <http://www.gnu.org/licenses/>.

my $np = Nagios::Plugin->new(
    shortname => 'SCM',
    usage     => "Usage: %s -w -c -f",
    version   => '0.1'
);

$np->add_arg(
    spec     => "warning|w=i",
    required => 1,
    help =>
"-w, --warning=INTEGER. Warning if warning threshold is higher than INTEGER",
);

$np->add_arg(
    spec     => "critical|c=i",
    required => 1,
    help =>
"-c, --critical=INTEGER. Critical if critical threshold is higher than INTEGER",
);

$np->add_arg(
    spec     => "configuration|f=s",
    required => 1,
    help     => "-f, --configuration=PATH",
);

$np->getopts();

my $stash;
my $cfg;

eval {

    $cfg = Siebel::Monitor::Config->new( file => $np->opts->configuration() );
    $comps = parse_config($config);

    my $daemon = Siebel::Srvrmgr::Daemon->new(
        {
            gateway     => $cfg->gateway(),
            enterprise  => $cfg->enterprise(),
            user        => $cfg->user(),
            password    => $cfg->password(),
            bin         => catfile( $cfg->srvrmgrPath(), $cfg->srvrmgrBin() ),
            is_infinite => 0,
            timeout     => 0,
            commands    => [
                Siebel::Srvrmgr::Daemon::Command->new(
                    command => 'load preferences',
                    action  => 'LoadPreferences',
                ),
                Siebel::Srvrmgr::Daemon::Command->new(
                    command => 'list comp',
                    action  => 'CheckComps',
                    params  => $cfg->servers()
                )
            ]
        }
    );

    $stash = Siebel::Srvrmgr::Daemon::ActionStash->instance();

    $daemon->run();
};

$np->nagios_die( 'Could not check components state: ' . $@ ) if ($@);

my $status = calc_status( $cfg, $stash );

$np->nagios_die(
    'Could not check components state: server or component not found')
  if ( $status == -1 );

my $threshold = $np->set_thresholds(
    warning  => $np->opts->warning(),
    critical => $np->opts->critical()
);

$np->nagios_exit(
    return_code => $np->check_threshold( $status ),
    message     => 'Components status is '. $status
);

sub calc_status {

    my $comps   = shift;    # array ref[hash ref]
    my $results = shift;    # Siebel::Srvrmgr::Daemon::ActionStash object
    my $server  = shift;

    my $status = 0;

    my $result_data = $results->get_stash();

    if ( exists( $result_data->{$server} ) ) {

        my $comps_status = $result_data->{$server};

        foreach my $comp ( @{$comps} ) {

            if ( exists( $comps_status->{ $comp->{name} } ) ) {

                unless ( $comps_status->{ $comp->{name} } ) {

                    $status += $comp->{criticality};

                }

            }
            else {

                $status = -1;
                last;    # a component verification is missing

            }

        }

    }
    else {

        $status = -1;

    }

    return $status;

}

