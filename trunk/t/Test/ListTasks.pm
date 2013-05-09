package Test::ListTasks;

use Test::Most;
use base 'Test::Class';

sub class { 'Siebel::Srvrmgr::ListParser::Output::ListTasks' }

sub startup : Tests(startup => 1) {

    my $test = shift;
    use_ok $test->class;
}

sub constructor : Tests(3) {

    my $test  = shift;
    my $class = $test->class;

    ok(
        my $list_tasks = $class->new(
            {
                data_type => 'list_tasks',
                raw_data  => [],
                cmd_line  => 'list tasks'
            }
        ),
        '... and the constructor should succeed'
    );

    isa_ok( $list_tasks, $class, '... and the object it returns' );

  TODO: {

        todo_skip
'Siebel::Srvrmgr::ListParser::Output::ListTasks parse method is not working',
          1;

        my $parsed_data = undef;

        cmp_deeply(
            $parsed_data,
            $list_tasks->get_data_parsed(),
            'get_data_parsed() returns the correct data structure'
        );

    }

}

1;
