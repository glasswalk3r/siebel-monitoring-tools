package Test::ListTasks;

use Test::Most;
use base 'Test';

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
#                raw_data  => [],
                raw_data  => $test->get_my_data(),
                cmd_line  => 'list tasks'
            }
        ),
        '... and the constructor should succeed'
    );

    isa_ok( $list_tasks, $class, '... and the object it returns' );

#  TODO: {

#        todo_skip
#'Siebel::Srvrmgr::ListParser::Output::ListTasks parse method is not working',
#          1;

        my $parsed_data = undef;

		use Data::Dumper;
		print Dumper($list_tasks->get_data_parsed());

        cmp_deeply(
            $parsed_data,
            $list_tasks->get_data_parsed(),
            'get_data_parsed() returns the correct data structure'
        );

#    }

}

1;
__DATA__
SV_NAME      CC_ALIAS                   TK_TASKID  TK_PID  TK_DISP_RUNSTATE
-----------  -------------------------  ---------  ------  ----------------
siebfoobar1  ServerMgr                  132120579  6302    Running
siebfoobar1  eCommunicationsObjMgr_ptb  131072058  27726   Completed
siebfoobar1  eCommunicationsObjMgr_ptb  131072048  27726   Running
siebfoobar1  eCommunicationsObjMgr_ptb  131072045  27726   Running
siebfoobar1  eCommunicationsObjMgr_ptb  131072036  27726   Completed
siebfoobar1  eCommunicationsObjMgr_ptb  131072014  27726   Running
siebfoobar2  ServerMgr                  130023426  5902    Running
siebfoobar2  eCommunicationsObjMgr_ptb  128975007  5464    Running
siebfoobar2  eCommunicationsObjMgr_ptb  128975001  5464    Completed
siebfoobar2  eCommunicationsObjMgr_ptb  128974995  5464    Running
siebfoobar2  eCommunicationsObjMgr_ptb  128974949  5464    Running
siebfoobar2  eCommunicationsObjMgr_ptb  128974931  5464    Running
siebfoobar2  eCommunicationsObjMgr_ptb  128974928  5464    Running
siebfoobar2  eChannelCMEObjMgr_ptb      127926815  5364    Completed

14 rows returned.

