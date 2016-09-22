use lib 't';
use Test::Siebel::Srvrmgr::ListParser;

my $fixed_test =
  Test::Siebel::Srvrmgr::ListParser->new(
    { output_file => [ 't', 'output', 'fixed', 'latest.txt' ] } );

my $delimited_test = Test::Siebel::Srvrmgr::ListParser->new(
    {
        col_sep     => '|',
        output_file => [ 't', 'output', 'delimited', 'latest.txt' ]
    }
);

Test::Class->runtests( $fixed_test, $delimited_test );

