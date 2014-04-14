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
                status      => 'Running'
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
                status      => 'Running'
            }
        );
    }
    'the constructor cannot accept undefined values for attributes';

    isa_ok( $test->{task}, $test->class() );

}

sub class_attributes : Tests(5) {

    my $test = shift;

    my @attribs = qw(server_name comp_alias id pid status);

    for my $attrib (@attribs) {

        has_attribute_ok( $test->{task}, $attrib );

    }

}

sub class_methods : Tests(6) {

    my $test = shift;

    can_ok( $test->{task}, 'new', 'get_server_name', 'get_comp_alias',
        'get_id', 'get_pid', 'get_status' );

    #                server_name => 'siebfoobar',
    #                comp_alias  => 'SRProc',
    #                id          => 5242888,
    #                pid         => 20503,
    #                status      => 'Running'

    is( $test->{task}->get_server_name(), 'siebfoobar' );
    is( $test->{task}->get_comp_alias(),  'SRProc' );
    is( $test->{task}->get_id(),          5242888 );
    is( $test->{task}->get_pid(),         20503 );
    is( $test->{task}->get_status(),      'Running' );

}

1;
