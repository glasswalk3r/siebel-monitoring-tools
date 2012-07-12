use warnings;
use strict;
use DBI qw(:sql_types);
use Nagios::Plugin;
use XML::XPath;

my $np;

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

my $xp;

eval {

    if ( defined( $np->opts->config() ) ) {

        $xp = XML::XPath->new( filename => $np->opts->config() );

    }
    else {

        $xp = XML::XPath->new( filename => 'remote.xml' );

    }

};

if ($@) {

    $np->nagios_die( $@, UNKNOWN );

}

alarm $xp->findvalue('siebelRemote/time-out');

my $total;

eval {

    $total = query_db(
        {
            to_route => $np->opts->pending(),
            dsn      => $xp->findvalue('/siebelRemote/db/DSN')->value(),
            user     => $xp->findvalue('/siebelRemote/db/user')->value(),
            password => $xp->findvalue('/siebelRemote/db/password')->value()
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

    my $dbh =
      DBI->connect( $params_ref->{dsn}, $params_ref->{user},
        $params_ref->{password} );
    $dbh->{RaiseError} = 1;

    my $sth = $dbh->prepare($query);
    $sth->bind_param( 1, $params_ref->{to_route}, SQL_INTEGER );
    $sth->execute();

    my $row = $sth->fetchrow_arrayref();

    $sth->finish();
    $dbh->disconnect();

    return $row->[0];

}
