package Test::Condition;

use Test::Most;
use Siebel::Srvrmgr::ListParser;
use Test::Moose 'has_attribute_ok';
use base 'Test::Class';

sub class { 'Siebel::Srvrmgr::Daemon::Condition' }

sub startup : Tests(startup => 1) {
    my $test = shift;
    use_ok $test->class;
}

sub constructor : Tests(24) {

    my $test  = shift;
    my $class = $test->class;

    can_ok( $class,
        qw(new get_cmd_counter is_infinite max_cmd_idx total_commands is_output_used set_output_used is_cmd_sent set_cmd_sent can_increment is_last_cmd reduce_total_cmd check add_cmd_counter reset_cmd_counter)
    );

    my $condition;

    ok(
        $condition = $class->new(
            {
                is_infinite    => 0,
                total_commands => 5
            }
        ),
        'the constructor works'
    );

    my @attribs = (
        'is_infinite', 'max_cmd_idx', 'total_commands', 'cmd_counter',
        'output_used', 'cmd_sent'
    );

    foreach my $attrib (@attribs) {

        has_attribute_ok( $condition, $attrib );

    }

    ok( $condition->check(), 'check methods must return true' );

    is( $condition->is_output_used, 0, 'is_output_used must return false' );

    $condition->set_output_used(1);

    is( $condition->is_output_used, 1, 'is_output_used must return true' );

    ok( $condition->can_increment(), 'can_increment must return true' );

    for ( 1 .. $condition->max_cmd_idx() ) {

        ok( $condition->add_cmd_counter(),
            'add_cmd_counter should be able to increment the cmd_counter' );

    }

    is(
        $condition->get_cmd_counter,
        $condition->max_cmd_idx(),
        'get_cmd_counter must return the same value of max_cmd_idx() method'
    );

    ok( $condition->is_last_cmd(), 'is_last_cmd must return true' );

    is( $condition->check(), 0,
        'check method must return false due conditions' );

    is( $condition->can_increment(), 0, 'can_increment must return false' );

    ok( $condition->reset_cmd_counter(), 'reset_cmd_counter works' );

    is( $condition->get_cmd_counter(),
        0, 'get_cmd_counter must return zero after reset' );

    my $condition2 = $class->new(
        {
            is_infinite    => 1,
            total_commands => 5
        }
    );

    for ( 1 .. $condition2->max_cmd_idx() ) {

        $condition2->add_cmd_counter();

    }

    ok( $condition2->check(), 'check must return true if is_infinite is true' );

    is( $condition2->get_cmd_counter(), 0,
'get_cmd_counter must return zero because of automatic reset from check method when is_infinite is true'
    );

}

1;
