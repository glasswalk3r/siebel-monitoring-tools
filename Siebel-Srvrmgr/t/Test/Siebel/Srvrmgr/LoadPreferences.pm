package Test::Siebel::Srvrmgr::LoadPreferences;

use Test::Most;
use Test::Moose qw(has_attribute_ok);
use base qw(Test::Siebel::Srvrmgr);

sub startup : Tests(startup => 1) {

    my $test = shift;
    use_ok $test->class;
}

sub constructor : Tests(6) {

    my $test  = shift;
    my $class = $test->class;

    can_ok( $class, 'new' );

    #extended method tests
    can_ok( $class, qw(parse get_location set_location) );

    ok(
        my $prefs = $class->new(
            {
                data_type => 'load_preferences',
                raw_data  => $test->get_my_data(), 
                cmd_line  => 'load preferences'
            }
        ),
        '... and the constructor should succeed'
    );

    has_attribute_ok( $prefs, 'location' );

    isa_ok( $prefs, $class, '... and the object it returns' );

    is(
        $prefs->get_location(),
        'C:\Siebel\8.0\web client\BIN\.Siebel_svrmgr.pref',
        'get_location returns the correct data'
    );

}

1;

__DATA__
srvrmgr:SUsrvr> load preferences
File: C:\Siebel\8.0\web client\BIN\.Siebel_svrmgr.pref

