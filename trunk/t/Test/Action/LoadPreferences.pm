package Test::Action::LoadPreferences;

use base 'Test::Class';
use Test::Pod::Coverage;
use Test::Most;
use Siebel::Srvrmgr::ListParser;
use Storable;

sub class { 'Siebel::Srvrmgr::Daemon::Action::LoadPreferences' }

sub startup : Tests(startup => 1) {
    my $test = shift;
    use_ok $test->class;
}

sub constructor : Tests(4) {

    my $test  = shift;
    my $class = $test->class;

    can_ok( $class, qw(new get_params get_parser get_params do) );

    my $action;

    ok(
        $action = $class->new(
            {
                parser =>
                  Siebel::Srvrmgr::ListParser->new( { is_warn_enabled => 1 } )
            }
        ),
        'the constructor should suceed'
    );

    pod_coverage_ok( $class, "$class is Pod covered" );

    my @data = <Test::Action::LoadPreferences::DATA>;
    close(Test::Action::LoadPreferences::DATA);

    ok( $action->do( \@data ), 'do methods works fine' );

}

1;

__DATA__
srvrmgr:SUsrvr> load preferences
File: C:\Siebel\8.0\web client\BIN\.Siebel_svrmgr.pref

