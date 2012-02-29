package Test::LoadPreferences;

use Test::Most;
use base 'Test::Class';

sub class { 'Siebel::Srvrmgr::ListParser::Output::LoadPreferences' }

sub startup : Tests(startup => 1) {

    my $test = shift;
    use_ok $test->class;
}

sub constructor : Tests(5) {

    my $test  = shift;
    my $class = $test->class;

    can_ok( $class, 'new' );

    #extended method tests
    can_ok( $class, qw(parse get_location set_location) );

	my @data = <Test::LoadPreferences::DATA>;
	close(Test::LoadPreferences::DATA);

    ok(
        my $prefs = $class->new(
            {
                data_type => 'load_preferences',
                raw_data  => \@data,
                cmd_line  => 'load preferences'
            }
        ),
        '... and the constructor should succeed'
    );

    isa_ok( $prefs, $class, '... and the object it returns' );

	is($prefs->get_location(), 'C:\Siebel\8.0\web client\BIN\.Siebel_svrmgr.pref', 'get_location returns the correct data');

}

1;

__DATA__
srvrmgr:SUsrvr> load preferences
File: C:\Siebel\8.0\web client\BIN\.Siebel_svrmgr.pref

