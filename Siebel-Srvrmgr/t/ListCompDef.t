use lib 't';
use Test::Siebel::Srvrmgr::ListParser::Output::Tabular::ListCompDef;
use File::Spec;

my $file = 'list_comp_def.txt';

my $fixed_test =
  Test::Siebel::Srvrmgr::ListParser::Output::Tabular::ListCompDef->new(
    structure_type => 'fixed',
    output_file =>
      File::Spec->catfile( 't', 'output', 'fixed', $file )
  );

my $delimited_test =
  Test::Siebel::Srvrmgr::ListParser::Output::Tabular::ListCompDef->new(
    structure_type => 'delimited',
    col_sep        => '|',
    output_file =>
      File::Spec->catfile( 't', 'output', 'delimited', $file )
  );

Test::Class->runtests( $fixed_test, $delimited_test );
