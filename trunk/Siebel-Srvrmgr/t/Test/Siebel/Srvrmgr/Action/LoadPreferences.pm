package Test::Action::LoadPreferences;

# :WARNING   :07/06/2013 17:39:55:: subclasses of Test::Action must "use base" Test::ReadMyself first due get_my_data method
use base qw(Test Test::Action);
use Test::Most;
use Siebel::Srvrmgr::ListParser;

sub class { 'Siebel::Srvrmgr::Daemon::Action::LoadPreferences' }

sub startup : Tests(startup => +1) {
    my $test = shift;
    $test->SUPER::startup();
    ok(
        $test->{action} = $test->class()->new(
            {
                parser => Siebel::Srvrmgr::ListParser->new()
            }
        ),
        'the constructor should succeed'
    );
}

sub class_methods : Test(+1) {

    my $test = shift;

    ok( $test->{action}->do( $test->get_my_data() ), 'do methods works fine' );

}

1;

__DATA__
srvrmgr:SUsrvr> load preferences
File: C:\Siebel\8.0\web client\BIN\.Siebel_svrmgr.pref

