use warnings;
use strict;
use XML::Simple;
use Siebel::Srvrmgr::Daemon;
use File::Spec::Functions qw(tmpdir catfile);
use Nagios::Plugin;
use Siebel::Srvrmgr::Daemon::ActionStash;

my $siebel_server = 'foobar';
my $bin = catfile( 'path_to', 'srvrmgr.exe' );

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
    help =>
"-f, --configuration=PATH",
);

$np->getopts();

my $comps;
my $stash;

eval {

	my $config = $np->opts->configuration();
	$comps  = parse_config($config);

	my $daemon = Siebel::Srvrmgr::Daemon->new(
		{
			server      => $siebel_server,
			gateway     => 'foobar',
			enterprise  => 'FOO',
			user        => 'sadmin',
			password    => 'foobar',
			bin         => $bin,
			is_infinite => 0,
			timeout     => 0,
			commands    => [
				{
					command => 'load preferences',
					action  => 'LoadPreferences',
				},
				{
					command => 'list comp',
					action  => 'CheckComps',
					params  => [ $siebel_server, $comps ]
				}
			]
		}
	);

	$stash = Siebel::Srvrmgr::Daemon::ActionStash->instance();

    $daemon->run();
};

$np->nagios_die('Could not check components state') if ( $@ );

my $status = calc_status( $comps, $stash, $siebel_server );

$np->nagios_die('Could not check components state') if ( $status == -1 );

my $threshold = $np->set_thresholds(
    warning  => $np->opts->warning(),
    critical => $np->opts->critical()
);

$np->nagios_exit(
    return_code => $np->check_threshold($status),
    message     => "Components status is $status"
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

sub parse_config {

    my $config = shift;
    my $ref    = XMLin($config);

    # hash ref
    my $server   = $ref->{server}->{name};
    my $defaults = $ref->{server}->{componentsGroups};

    my @comps;

    my $xml_comps = $ref->{server}->{components};

    foreach my $comp_name ( keys( %{$xml_comps} ) ) {

        my $status = undef;

        if ( exists( $xml_comps->{$comp_name}->{OKStatus} ) ) {

            $status = $xml_comps->{$comp_name}->{OKStatus};

        }
        else {

            my $comp_group = $xml_comps->{$comp_name}->{ComponentGroup};
            $status = $defaults->{$comp_group}->{defaultOKStatus};

        }

        die "Status must be defined for $comp_name\n"
          unless ( defined($status) );

        push(
            @comps,
            {
                name        => $comp_name,
                ok_status   => $status,
                criticality => $xml_comps->{$comp_name}->{criticality}
            }
        );

    }

    return \@comps;

}

