package Test::Siebel::Srvrmgr::ListParser::Output::LoadPreferences;

use Test::Most;
use Test::Moose qw(has_attribute_ok);
use base qw(Test::Siebel::Srvrmgr::ListParser::Output);

sub get_data_type {

    return 'load_preferences';

}

sub get_cmd_line {

    return 'load preferences';

}

sub class_attributes : Test(+1) {

    my $test = shift;

    has_attribute_ok( $test->get_output(), 'location' );

}

sub class_methods : Tests(+2) {

    my $test = shift;

    can_ok( $test->get_output(), qw(get_location set_location) );

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

