package Test::Task;

use Test::Most;
use Test::Moose;
use base 'Test';

sub class { 'Siebel::Srvrmgr::ListParser::Output::ListTasks::Task' }

sub startup : Tests(startup => 1) {

    my $test = shift;
    use_ok $test->class;
}

sub constructor : Tests(9) {

    my $test  = shift;
    my $class = $test->class;

    can_ok( $class, 'new', 'get_server_name', 'get_comp_alias',
        'get_id', 'get_pid', 'get_status' );

    my @attribs = qw(server_name comp_alias id pid status);

    for my $attrib (@attribs) {

        has_attribute_ok( $class, $attrib, "$class has the attribute $attrib" );

    }

    ok(
        my $task = $class->new(
            {
                server_name => 'siebfoobar',
                comp_alias  => 'SRProc',
                id          => 5242888,
                pid         => 20503,
                status      => 'Running'
            }
        ),
        '... and the constructor should succeed'
    );

    dies_ok {
        my $task = $class->new(
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

    isa_ok( $task, $class, '... and the object it returns' );

}

1;
