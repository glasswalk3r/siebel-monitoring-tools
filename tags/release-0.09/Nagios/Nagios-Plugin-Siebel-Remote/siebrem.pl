use warnings;
use strict;
use DBI qw(:sql_types);
use Nagios::Plugin;
use Config::Tiny;

# Yes, it is a global variable. See $SIG{INT} handler for details
our $dbh;
my $np;

$SIG{'INT'} = 'CLEANUP';

$SIG{'ALRM'} =
  sub { $np->nagios_die('Timeout trying to reach database'), CRITICAL };

$np = Nagios::Plugin->new(
    usage => "Usage: %s [ -p|--pending=<value> ] [ -c|--config=<filename> ]"
      . "[ -c|--critical=<threshold> ] [ -w|--warning=<threshold> ]",
    version => 0.01
);

$np->add_arg(
    spec     => 'warning|w=s',
    required => 1,
    help     => '-w, --warning=INTEGER:INTEGER. See '
      . 'http://nagiosplug.sourceforge.net/developer-guidelines.html#THRESHOLDFORMAT '
      . 'for the threshold format.',
);

$np->add_arg(
    spec     => 'critical|w=s',
    required => 1,
    help     => '-c, --critical=INTEGER:INTEGER. See '
      . 'http://nagiosplug.sourceforge.net/developer-guidelines.html#THRESHOLDFORMAT '
      . 'for the threshold format.',
);

$np->add_arg(
    spec     => 'pending|w=s',
    required => 1,
    help =>
'-p, --pending=INTEGER:INTEGER. Defines the minimum amount of pending transactions to consider in the Siebel Remote tables.'
);

$np->add_arg(
    spec     => 'config|w=s',
    required => 0,
    help =>
'-c, --config=STRING:STRING. Complete path to the XML file to be used for configuration. Default to remote.xml in the current directory where the program is executed.'
);

$np->getopts();

my $config;

eval {

    if ( defined( $np->opts->config() ) ) {

        $config = Config::Tiny->read( $np->opts->config() );

    }
    else {

        $config = Config::Tiny->read('remote.cfg');

    }

};

if ($@) {

    $np->nagios_die( $@, UNKNOWN );

}

alarm $config->{_}->{timeout};

my $total;

eval {

    $total = query_db(
        {
            to_route => $np->opts->pending(),
            dsn      => $config->{ODBC}->{dsn},
            user     => $config->{ODBC}->{user},
            password => $config->{ODBC}->{password}
        }
    );

};

if ($@) {

    $np->nagios_die( $@, UNKNOWN );

}

my $threshold = $np->set_thresholds(
    warning  => $np->opts->warning,
    critical => $np->opts->critical
);

$np->add_perfdata(
    label => 'number of users with pending transaction above the acceptable',
    value => $total,
    uom   => '',
    threshold => $threshold,
);

$np->nagios_exit(
    return_code => $np->check_threshold($total),
    message     => 'Users with transactions to be routed above '
      . $np->opts->pending() . ': '
      . $total
);

sub query_db {

    my $params_ref = shift;    #hash reference

    my $query = <<BLOCK;
SELECT COUNT(*) AS TOTAL
FROM SIEBEL.S_NODE N,
  SIEBEL.S_DOCK_STATUS LR,
  (SELECT MAX(TXN_ID) MAX_TXN_ID FROM SIEBEL.S_DOCK_TXN_LOG
  ) A,
  SIEBEL.S_USER SUSER,
  SIEBEL.S_PARTY_PER SPARTYPER,
  SIEBEL.S_POSTN SPOSTN
WHERE N.EFF_END_DT     IS NULL
AND LR.NODE_ID          = N.ROW_ID
AND LR.TYPE             = 'ROUTE'
AND LR.LOCAL_FLG        = 'Y'
AND LR.LAST_TXN_NUM    <> -1
AND SUSER.LOGIN         = N.NAME
AND SPARTYPER.PERSON_ID = SUSER.ROW_ID
AND SPOSTN.ROW_ID       = SPARTYPER.PARTY_ID
AND (A.MAX_TXN_ID - LR.LAST_TXN_NUM) >= ? 
BLOCK

    $dbh = DBI->connect(
        $params_ref->{dsn}, $params_ref->{user},
        $params_ref->{password}, { RaiseError => 1 }
    );

    my $sth = $dbh->prepare($query);
    $sth->bind_param( 1, $params_ref->{to_route}, SQL_INTEGER );
    $sth->execute();

    my $row = $sth->fetchrow_arrayref();

    $sth->finish();
    $dbh->disconnect();

    return $row->[0];

}

sub CLEANUP {

    $dbh->disconnect() if ( defined($dbh) );
    die 'Received INTERRUPT signal, aborting execution';

}
