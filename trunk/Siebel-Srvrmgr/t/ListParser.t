use lib 't';
use Test::Siebel::Srvrmgr::ListParser;

my $fixed_test =
  Test::Siebel::Srvrmgr::ListParser->new(
    { output_file => [ 't', 'output', 'fixed', '8.0.0.2_20412.txt' ] } );

my $delimited_test = Test::Siebel::Srvrmgr::ListParser->new(
    {
        col_sep     => '|',
        output_file => [ 't', 'output', 'delimited', '8.0.0.2_20412.txt' ]
    }
);

Test::Class->runtests( $fixed_test, $delimited_test );

