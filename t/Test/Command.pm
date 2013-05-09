package Test::Comp;

use Test::Most;
use Test::Moose 'has_attribute_ok';
use base 'Test::Class';
use Siebel::Srvrmgr::Daemon::Command;

sub class { 'Siebel::Srvrmgr::Daemon::Command' }

sub startup : Tests(startup => 1) {

    my $test = shift;
    use_ok $test->class;
}

sub constructor : Tests(7) {

    my $test  = shift;
    my $class = $test->class;

    can_ok( $class, 'new' );

    #extended method tests
    can_ok( $class, qw(get_command get_action get_params) );

    my $action;

    ok(
        $action = Siebel::Srvrmgr::Daemon::Command->new(
            {
                command => 'list comps',
                action  => 'Siebel::Srvrmgr::Daemon::Action',
                params  => [ 'parameter1', 'parameter2' ]
            }
        )
    );

    isa_ok( $action, $class, '... and the object it returns' );

    foreach my $attrib_name (qw(command action params)) {

        has_attribute_ok( $action, $attrib_name );

    }

}

1;
