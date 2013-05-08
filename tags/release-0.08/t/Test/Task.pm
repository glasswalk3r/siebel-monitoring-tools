package Test::Task;

use Test::Most;
use Test::Moose;
use base 'Test::Class';

sub class { 'Siebel::Srvrmgr::ListParser::Output::ListTasks::Task' }

sub startup : Tests(startup => 1) {

    my $test = shift;
    use_ok $test->class;
}

sub constructor : Tests(18) {

    my $test  = shift;
    my $class = $test->class;

    can_ok(
        $class,            'new',
        'get_server_name', 'get_comp_alias',
        'get_id',          'get_pid',
        'get_run_mode',    'get_comp_alias',
        'get_start',       'get_cg_alias',
        'get_end',         'get_status',
        'get_parent_id',   'get_incarn_num',
        'get_label',       'get_type',
        'get_last_ping_time'
    );

    my @attribs =
      qw(server_name comp_alias id pid run_mode start end status cg_alias parent_id incarn_num label type last_ping_time);

    for my $attrib (@attribs) {

        has_attribute_ok( $class, $attrib, "$class has the attribute $attrib" );

    }

    ok(
        my $task = $class->new(
            {
                server_name    => 'siebfoobar',
                comp_alias     => 'SRProc',
                id             => 5242888,
                pid            => 20503,
                run_mode       => 'Interactive',
                start          => '2013-04-22 15:32:28',
                end            => '2000-00-00 00:00:00',
                status         => 'Running',
                cg_alias       => 'SystemAux',
                parent_id      => 0,
                incarn_num     => 0,
                label          => '',
                type           => 'Normal',
                last_ping_time => ''
            }
        ),
        '... and the constructor should succeed'
    );

    dies_ok {
        my $task = $class->new(
            {
                server_name    => 'siebfoobar',
                comp_alias     => 'SRProc',
                id             => 5242888,
                pid            => 20503,
                run_mode       => 'Interactive',
                start          => '2013-04-22 15:32:28',
                end            => '2000-00-00 00:00:00',
                status         => 'Running',
                cg_alias       => 'SystemAux',
                parent_id      => undef,
                incarn_num     => 0,
                label          => undef,
                type           => 'Normal',
                last_ping_time => undef
            }
        );
    }
    'the constructor cannot accept undefined values for attributes';

    isa_ok( $task, $class, '... and the object it returns' );

}

1;
