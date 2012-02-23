package Test::ActionFactory;

use Test::Pod::Coverage;
use Test::Most;
use Siebel::Srvrmgr::ListParser;
use base 'Test::Class';

sub class { 'Siebel::Srvrmgr::Daemon::ActionFactory' }

sub startup : Tests(startup => 1) {

    my $test = shift;
    use_ok $test->class;
}

sub xunda : Tests(4) {

    my $test  = shift;
    my $class = $test->class;

    can_ok( $class, qw(create) );

    isa_ok(
        $class->create(
            'ListComps',
            {
                parser => Siebel::Srvrmgr::ListParser->new(),
                params => ['somefile']
            }
        ),
        'Siebel::Srvrmgr::Daemon::Action::ListComps',
        'create method returns an object'
    );

    dies_ok(
        sub { $class->create('FooBar') },
'create method raises an exception trying to instantiate an object from a invalid class'
    );

    pod_coverage_ok( $class, "$class is Pod covered" );

}

1;
