package Test::Siebel::Srvrmgr::ListParser::Output::LoadPreferences;

use Test::Most;
use base qw(Test::Siebel::Srvrmgr::ListParser::Output);

sub get_data_type {

    return 'load_preferences';

}

sub get_cmd_line {

    return 'load preferences';

}

sub class_attributes : Test {

    my $test = shift;

    $test->SUPER::class_attributes( ['location'] );

}

sub class_methods : Tests(+1) {

    my $test = shift;

    $test->SUPER::class_methods( [qw(get_location set_location)] );

    is(
        $test->get_output()->get_location(),
        'C:\Siebel\8.0\web client\BIN\.Siebel_svrmgr.pref',
        'get_location returns the correct data'
    );

}

1;

__DATA__
srvrmgr:SUsrvr> load preferences
File: C:\Siebel\8.0\web client\BIN\.Siebel_svrmgr.pref

