package Test::Siebel::Srvrmgr::ListParser::Output::ListTasks::Task;

use Test::Most;
use Test::Moose;
use base 'Test::Siebel::Srvrmgr';

sub _constructor : Tests(3) {

    my $test = shift;

    ok(
        $test->{task} = $test->class()->new(
            {
                server_name => 'siebfoobar',
                comp_alias  => 'SRProc',
                id          => 5242888,
                pid         => 20503,
                run_state   => 'Running'
            }
        ),
        'the constructor should succeed'
    );

    dies_ok {
        my $task = $test->class()->new(
            {
                server_name => 'siebfoobar',
                comp_alias  => 'SRProc',
                id          => 5242888,
                pid         => undef,
                run_state   => 'Running'
            }
        );
    }
    'the constructor cannot accept undefined values for attributes';

    isa_ok( $test->{task}, $test->class() );

}

sub class_attributes : Tests(no_plan) {

    my $test = shift;

    my @attribs =
      qw(server_name comp_alias id pid run_state run_mode start_time end_time status group_alias parent_id incarn_no label type ping_time);
    $test->num_tests( scalar(@attribs) );

    for my $attrib (@attribs) {

        has_attribute_ok( $test->{task}, $attrib );

    }

}

sub class_methods : Tests(6) {

    my $test = shift;

    can_ok(
        $test->{task},     'new',
        'get_server_name', 'get_comp_alias',
        'get_id',          'get_pid',
        'get_run_state',   'get_run_mode',
        'get_start_time',  'get_end_time',
        'get_status',      'get_group_alias',
        'get_parent_id',   'get_incarn_no',
        'get_label',       'get_type',
        'get_ping_time'
    );

    is( $test->{task}->get_server_name(), 'siebfoobar' );
    is( $test->{task}->get_comp_alias(),  'SRProc' );
    is( $test->{task}->get_id(),          5242888 );
    is( $test->{task}->get_pid(),         20503 );
    is( $test->{task}->get_run_state(),      'Running' );

}

1;
