use warnings;
use strict;
use DBI qw(:sql_types);
use Nagios::Plugin;

my $np = Nagios::Plugin->new( usage => "Usage: %s [ -v|--verbose ] "
      . "[ -c|--critical=<threshold> ] [ -w|--warning=<threshold> ]" );

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
    help     => '-p, --pending=INTEGER:INTEGER. Defines the minimum amount of pending transactions to consider in the Siebel Remote tables.'
);

$np->getopts();

my $total = query_db();

$np->nagios_exit(
    return_code => $np->check_threshold(
        check    => $total,
        warning  => $np->opts->warning(),
        critical => $np->opts->critical()
    )
);

sub query_db {

    my $to_route = shift;
    my $dsn      = 'dbi:ODBC:FOOBAR';
    my $user     = 'FOO';
    my $password = 'BAR';

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

    my $dbh = DBI->connect( $dsn, $user, $password );
    $dbh->{RaiseError} = 1;
    my $sth = $dbh->prepare($query);
    $sth->bind_param( 1, $to_route, SQL_INTEGER );
    $sth->execute();

    my $row = $sth->fetchrow_arrayref();

    $sth->finish();
    $dbh->disconnect();

    return $row->[0];

}
