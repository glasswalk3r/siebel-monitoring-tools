package Test::Siebel::Srvrmgr::ListParser::Output::ListTasks::Task;

use Test::Most;
use Test::Moose;
use DateTime;
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
                run_state   => 'Running',
                start_time  => '2014-08-21 02:52:00',
                end_time    => '2000-00-00 00:00:00',
                curr_time   => DateTime->new(
                    year   => 2014,
                    month  => 8,
                    day    => 21,
                    hour   => 10,
                    minute => 42,
                    second => 5
                )
            }
        ),
        'the constructor should succeed'
    );

	note($test->{task}->get_duration);

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

sub class_methods : Tests(9) {

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
        'get_ping_time',   'to_string',
        'to_string_header'
    );

    is( $test->{task}->get_server_name(),
        'siebfoobar', 'get_server_name method returns the expected value' );
    is( $test->{task}->get_comp_alias(),
        'SRProc', 'get_comp_alias method returns the expected value' );
    is( $test->{task}->get_id(),
        5242888, 'get_id method returns the expected value' );
    is( $test->{task}->get_pid(),
        20503, 'get_pid method returns the expected value' );
    is( $test->{task}->get_run_state(),
        'Running', 'get_run_state method returns the expected value' );

    dies_ok { $test->{task}->to_string }
    'to_string expects a single character as parameter';
    my $separator = '|';
    my $string    = $test->{task}->to_string($separator);
    is(
        $string,
        'SRProc|||5242888||||20503|||Running|siebfoobar|||',
        'to_string returns the expected string'
    );
    my $header = $test->{task}->to_string_header($separator);
    is(
        $header,
'comp_alias|end_time|group_alias|id|incarn_no|label|parent_id|pid|ping_time|run_mode|run_state|server_name|start_time|status|type',
        'to_string_header returns the expected string'
    );

}

1;
