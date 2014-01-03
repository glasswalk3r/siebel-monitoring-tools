package Test::Siebel::Srvrmgr::ListParser::Output::Tabular::ListParams;

use Test::Most;
use Test::Moose 'has_attribute_ok';
use base 'Test::Siebel::Srvrmgr::ListParser::Output::Tabular';

sub get_data_type {

    return 'list_params';

}

sub get_cmd_line {

    return 'list params for server siebel1 component SRProc';

}

sub class_methods : Tests(+2) {

    my $test = shift;

    $test->SUPER::class_methods(
        [qw(parse get_server get_comp_alias _set_details)] );

    is( $test->get_output()->get_server(),
        'siebel1', 'get_server returns the expected server name' );

    is( $test->get_output()->get_comp_alias(),
        'SRProc', 'get_comp_alias returns the expected component alias' );

}

sub class_attributes : Tests(no_plan) {

    my $test = shift;

    $test->SUPER::class_attributes( [qw(server comp_alias)] );

}

1;
