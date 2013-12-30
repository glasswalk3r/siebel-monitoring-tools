package Test::Siebel::Srvrmgr::ListParser::Output::ListTasks;

use Test::Most;
use Siebel::Srvrmgr::ListParser::Output::ListTasks::Task;
use Siebel::Srvrmgr::ListParser::Output::ListTasks;
use base qw(Test::Siebel::Srvrmgr::ListParser::Output);

sub get_data_type {

    return 'list_tasks';

}

sub get_cmd_line {

    return 'list tasks';

}

# :TODO      :10/06/2013 16:40:59:: have to move all test classes to a new package name to avoid clashing with other packages like Test::Output
# :TODO      :10/06/2013 16:30:22:: this is a subclass, the parent tests are missing! should use inheritance here
sub class_methods : Tests(+5) {

    my $test = shift;

    my $parsed_data = {
        'siebfoobar1' => [
            Siebel::Srvrmgr::ListParser::Output::ListTasks::Task->new(
                {
                    'comp_alias'  => 'ServerMgr',
                    'pid'         => '6302',
                    'status'      => 'Running',
                    'id'          => '132120579',
                    'server_name' => 'siebfoobar1'
                }
            ),
            Siebel::Srvrmgr::ListParser::Output::ListTasks::Task->new(
                {
                    'comp_alias'  => 'eCommunicationsObjMgr_ptb',
                    'pid'         => '27726',
                    'status'      => 'Completed',
                    'id'          => '131072058',
                    'server_name' => 'siebfoobar1'
                }
            ),
        ],
        'siebfoobar2' => [
            Siebel::Srvrmgr::ListParser::Output::ListTasks::Task->new(
                {
                    'comp_alias'  => 'ServerMgr',
                    'pid'         => '5902',
                    'status'      => 'Running',
                    'id'          => '130023426',
                    'server_name' => 'siebfoobar2'
                }
            ),
            Siebel::Srvrmgr::ListParser::Output::ListTasks::Task->new(
                {
                    'comp_alias'  => 'eCommunicationsObjMgr_ptb',
                    'pid'         => '5464',
                    'status'      => 'Running',
                    'id'          => '128975007',
                    'server_name' => 'siebfoobar2'
                }
            ),
            Siebel::Srvrmgr::ListParser::Output::ListTasks::Task->new(
                {
                    'comp_alias'  => 'eChannelCMEObjMgr_ptb',
                    'pid'         => '5364',
                    'status'      => 'Completed',
                    'id'          => '127926815',
                    'server_name' => 'siebfoobar2'
                }
            ),
        ]
    };

    ok( $test->get_output()->get_data_parsed(), 'get_data_parsed works' );

    cmp_deeply(
        $parsed_data,
        $test->get_output()->get_data_parsed(),
        'get_data_parsed() returns the correct data structure'
    );

    ok(
        $test->get_output()->set_data_parsed(
            {
                'my_server' => [
                    Siebel::Srvrmgr::ListParser::Output::ListTasks::Task->new(
                        {
                            'comp_alias'  => 'eChannelCMEObjMgr_ptb',
                            'pid'         => '5364',
                            'status'      => 'Completed',
                            'id'          => '127926815',
                            'server_name' => 'siebfoobar2'
                        }
                    )
                ]
            }
        ),
        'set_data_parsed works with correct parameters'
    );

    dies_ok { $test->get_output()->set_data_parsed('foobar') }
    'set_data_parsed dies with incorrect parameters';

# :TODO      :10/06/2013 18:09:50:: Siebel::Srvrmgr::ListParser::Output should be tested against undefined data reference to be parsed
# after initial clean up
    my @invalid_output =
      ( 'foobar', 'bar', 'foo', 'floor', 'for', 'yadayadayada', 'garbage' );

    $test->get_output()->set_raw_data( \@invalid_output );

    dies_ok { $test->get_output()->parse() }
    'dies with invalid output to be parsed due restricted fields/columns';

}

1;
__DATA__
SV_NAME      CC_ALIAS                   TK_TASKID  TK_PID  TK_DISP_RUNSTATE
-----------  -------------------------  ---------  ------  ----------------
siebfoobar1  ServerMgr                  132120579  6302    Running
siebfoobar1  eCommunicationsObjMgr_ptb  131072058  27726   Completed
siebfoobar2  ServerMgr                  130023426  5902    Running
siebfoobar2  eCommunicationsObjMgr_ptb  128975007  5464    Running
siebfoobar2  eChannelCMEObjMgr_ptb      127926815  5364    Completed

14 rows returned.

