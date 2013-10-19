#!/usr/bin/perl
use warnings;
use strict;
use RPC::XML;
use RPC::XML::Client;
use Nagios::Plugin;
use TryCatch;

my $np = Nagios::Plugin->new(
    shortname => 'NRPC',
    usage     => "Usage: %s -w -c -h -a -p -s",
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
    spec     => "hostname|h=s",
    required => 1,
    help => "-h, --hostname=STRING. Name of the RPC XML Server to connect to",
);

$np->add_arg(
    spec     => "alias|a=s",
    required => 1,
    help =>
"-a, --alias=STRING. The component alias to retrieve status from RPC XML Server",
);

$np->add_arg(
    spec     => "port|p=i",
    required => 1,
    help     => "-p, --port=INTEGER. The RPC XML Server port to connect to",
);

$np->add_arg(
    spec     => "server|s=s",
    required => 1,
    help     => "-s, --server=STRING. The Siebel Server name to check the component status",
);

$np->getopts();
$np->shortname( $np->opts()->alias() );

my $resp;

try {

    my $cli = RPC::XML::Client->new(
        'http://' . $np->opts()->hostname() . ':' . $np->opts()->port() );

    my $request = RPC::XML::request->new(
        'siebel.srvrmgr.xmlrpc.checkComponent',
        RPC::XML::string->new( $np->opts()->server() ), 
        RPC::XML::string->new( $np->opts()->alias() )
    );

    $resp = $cli->send_request($request);

}
catch($e) {

    $np->nagios_die( 'Could not check the component state: ' . $@ );

}

SWITCH: {

    if ( ( ref($resp) ) eq 'RPC::XML::struct' ) {

        my $status;

        if ( $resp->{isOK} ) {

            $status = 0

        }
        else {

            $status = $resp->{criticality};

        }

        my $threshold = $np->set_thresholds(
            warning  => $np->opts->warning(),
            critical => $np->opts->critical()
        );

        $np->nagios_exit(
            return_code => $np->check_threshold($status),
            message     => 'Components status is ' . $status
        );

        last SWITCH;

    }

    if ( ( ref($resp) ) eq 'RPC::XML::fault' ) {

        $np->nagios_die( 'An error was returned while checking the component: '
              . $resp->string() );

        last SWITCH;
    }
    else {
        $np->nagios_die(
            'Received an unrecognized response from RPC XML server: '
              . ref($resp) );
        last SWITCH;
    }

}

