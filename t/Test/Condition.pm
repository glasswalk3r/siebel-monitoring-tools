package Test::Condition;

use Test::Pod::Coverage;
use Test::Most;
use Siebel::Srvrmgr::ListParser;
use base 'Test::Class';

sub class { 'Siebel::Srvrmgr::Daemon::Condition' }

sub startup : Tests(startup => 1) {
    my $test = shift;
    use_ok $test->class;
}

sub constructor : Tests(13) {

    my $test  = shift;
    my $class = $test->class;

    can_ok( $class,
        qw(new get_cmd_counter is_infinite max_cmd_idx total_commands is_output_used set_output_used cmd_sent reduce_total_cmd check add_cmd_counter reset_cmd_counter)
    );

    my $condition;

    ok(
        $condition = $class->new(
            {
                is_infinite    => 0,
                total_commands => 10
            }
        ),
        'the constructor should suceed'
    );

    $condition->set_output_used(1);

    for ( 1 .. $condition->max_cmd_idx() ) {

        ok( $condition->add_cmd_counter(),
            'add_cmd_counter should be able to increment the cmd_counter' );

    }

    is( $condition->get_cmd_counter, $condition->max_cmd_idx(),
        'get_cmd_counter must return the same value of max_cmd_idx() method' );

    pod_coverage_ok( $class, "$class is Pod covered" );

}

1;
