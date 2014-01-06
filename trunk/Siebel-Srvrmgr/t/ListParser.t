use File::Spec;
use lib 't';
use Test::Siebel::Srvrmgr::ListParser;

my $fixed_test =
  Test::Siebel::Srvrmgr::ListParser->new(
    structure_type => 'fixed',
    output_file =>
      File::Spec->catfile( 't', 'output', 'fixed', '8.0.0.2_20412.txt' )
  );

my $delimited_test =
  Test::Siebel::Srvrmgr::ListParser->new(
    structure_type => 'delimited',
    col_sep        => '|',
    output_file =>
      File::Spec->catfile( 't', 'output', 'delimited', '8.0.0.2_20412.txt' )
  );

Test::Class->runtests( $fixed_test, $delimited_test );


