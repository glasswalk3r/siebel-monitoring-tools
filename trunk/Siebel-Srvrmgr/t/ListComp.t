use File::Spec;
use lib 't';
use Test::Siebel::Srvrmgr::ListParser::Output::Tabular::ListComp;

my $fixed_test =
  Test::Siebel::Srvrmgr::ListParser::Output::Tabular::ListComp->new(
    structure_type => 'fixed',
    output_file =>
      File::Spec->catfile( 't', 'output', 'fixed', 'list_comp.txt' )
  );

my $delimited_test =
  Test::Siebel::Srvrmgr::ListParser::Output::Tabular::ListComp->new(
    structure_type => 'delimited',
    col_sep        => '|',
    output_file =>
      File::Spec->catfile( 't', 'output', 'delimited', 'list_comp.txt' )
  );

Test::Class->runtests( $fixed_test, $delimited_test );
