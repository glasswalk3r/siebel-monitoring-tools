use Siebel::Srvrmgr::ListParser;
use Siebel::Srvrmgr::Daemon::Action::Dumper;
use Test::Output qw(:stdout);
use Test::More tests => 1;
use Data::Dumper;

stdout_like( \&test_dumper, qr/^\$VAR1\s\=\s\[\n\s{10}\'SV_NAME/, 'do methods creates the correct output' );

sub test_dumper {

my @data = <DATA>;
close(DATA);

    my $action = Siebel::Srvrmgr::Daemon::Action::Dumper->new(
        {
            parser =>
              Siebel::Srvrmgr::ListParser->new( { is_warn_enabled => 1 } )
        }
    );

    print $action->do( \@data );

}

1;

__DATA__
SV_NAME  CC_ALIAS        TK_TASKID  TK_PID  TK_DISP_RUNSTATE  CC_RUNMODE   TK_START_TIME        TK_END_TIME          TK_STATUS                                                                                CG_ALIAS   TK_PARENT_T  CC_INCARN_NO  TK_LABEL                  TK_TASKTYPE  TK_PING_TIM  
-------  --------------  ---------  ------  ----------------  -----------  -------------------  -------------------  ---------------------------------------------------------------------------------------  ---------  -----------  ------------  ------------------------  -----------  -----------  
SUsrvr   ServerMgr       32505858   916     Running           Interactive  2012-02-13 08:14:36  2000-00-00 00:00:00  Processing "List Tasks" command                                                          System                  0                                       Normal                    
SUsrvr   TaskLogCleanup  31457282   3292    Running           Background   2012-02-13 08:14:15  2000-00-00 00:00:00                                                                                           TaskUI                  0             SADMIN                    Normal                    
SUsrvr   TxnProc         29360130   3160    Running           Background   2012-02-13 08:14:15  2000-00-00 00:00:00  Cleaning routed .dx files...                                                             Remote                  0                                       Normal                    
SUsrvr   TxnRoute        28311554   3104    Running           Background   2012-02-13 08:14:15  2000-00-00 00:00:00  Iteration 1: Sleeping for 60 seconds...                                                  Remote                  0                                       Normal                    
SUsrvr   TxnMerge        25165826   2980    Running           Background   2012-02-13 08:14:14  2000-00-00 00:00:00  Iteration 0: Sleeping for 40 seconds...                                                  Remote                  0                                       Normal                    
SUsrvr   SBRWorkMon      13631490   2776    Running           Background   2012-02-13 08:14:13  2000-00-00 00:00:00  Sleeping for 50 seconds...                                                               Workflow                0                                       Normal                    
SUsrvr   SBRWorkActn     9437186    2736    Running           Background   2012-02-13 08:14:12  2000-00-00 00:00:00  Sleeping for 50 seconds...                                                               Workflow                0                                       Normal                    
SUsrvr   SvrTblCleanup   8388610    2392    Running           Background   2012-02-13 08:14:07  2000-00-00 00:00:00  Invoking method DelCompletedDelExpiredReq for service Message Board Maintenance Service  SystemAux               0             SADMIN                    Normal                    
SUsrvr   SvrTaskPersist  7340034    2448    Running           Background   2012-02-13 08:14:07  2000-00-00 00:00:00  Invoking method InsertUpdateTaskHistory for service Message Board Maintenance Service    SystemAux               0             SADMIN                    Normal                    
SUsrvr   SRProc          5242888    2416    Running           Interactive  2012-02-13 08:14:10  2000-00-00 00:00:00                                                                                           SystemAux               0                                       Normal                    
SUsrvr   SRProc          5242885    2416    Running           Interactive  2012-02-13 08:14:09  2000-00-00 00:00:00                                                                                           SystemAux               0             Forwarding Task           Worker                    
SUsrvr   SRBroker        3145755    2312    Running           Interactive  2012-02-13 08:14:15  2000-00-00 00:00:00                                                                                           System                  0                                       Normal                    
SUsrvr   SRBroker        3145754    2312    Running           Interactive  2012-02-13 08:14:15  2000-00-00 00:00:00                                                                                           System                  0                                       Normal                    
SUsrvr   SRBroker        3145753    2312    Running           Interactive  2012-02-13 08:14:15  2000-00-00 00:00:00                                                                                           System                  0                                       Normal                    
SUsrvr   SRBroker        3145752    2312    Running           Interactive  2012-02-13 08:14:15  2000-00-00 00:00:00                                                                                           System                  0                                       Normal                    
SUsrvr   SRBroker        3145751    2312    Running           Interactive  2012-02-13 08:14:15  2000-00-00 00:00:00                                                                                           System                  0                                       Normal                    
SUsrvr   SRBroker        3145750    2312    Running           Interactive  2012-02-13 08:14:15  2000-00-00 00:00:00                                                                                           System                  0                                       Normal                    
SUsrvr   SRBroker        3145749    2312    Running           Interactive  2012-02-13 08:14:15  2000-00-00 00:00:00                                                                                           System                  0                                       Normal                    
SUsrvr   SRBroker        3145748    2312    Running           Interactive  2012-02-13 08:14:15  2000-00-00 00:00:00                                                                                           System                  0                                       Normal                    
SUsrvr   SRBroker        3145747    2312    Running           Interactive  2012-02-13 08:14:15  2000-00-00 00:00:00                                                                                           System                  0                                       Normal                    
SUsrvr   SRBroker        3145746    2312    Running           Interactive  2012-02-13 08:14:15  2000-00-00 00:00:00                                                                                           System                  0                                       Normal                    
SUsrvr   SRBroker        3145745    2312    Running           Interactive  2012-02-13 08:14:15  2000-00-00 00:00:00                                                                                           System                  0                                       Normal                    
SUsrvr   SRBroker        3145744    2312    Running           Interactive  2012-02-13 08:14:15  2000-00-00 00:00:00                                                                                           System                  0                                       Normal                    
SUsrvr   SRBroker        3145743    2312    Running           Interactive  2012-02-13 08:14:13  2000-00-00 00:00:00                                                                                           System                  0                                       Normal                    
SUsrvr   SRBroker        3145742    2312    Running           Interactive  2012-02-13 08:14:13  2000-00-00 00:00:00                                                                                           System                  0                                       Normal                    
SUsrvr   SRBroker        3145740    2312    Running           Interactive  2012-02-13 08:14:09  2000-00-00 00:00:00                                                                                           System                  0                                       Normal                    
SUsrvr   SRBroker        3145739    2312    Running           Interactive  2012-02-13 08:14:08  2000-00-00 00:00:00                                                                                           System                  0                                       Normal                    
SUsrvr   SRBroker        3145738    2312    Running           Interactive  2012-02-13 08:14:08  2000-00-00 00:00:00                                                                                           System                  0                                       Normal                    
SUsrvr   SRBroker        3145736    2312    Running           Interactive  2012-02-13 08:14:02  2000-00-00 00:00:00                                                                                           System                  0             Store task                Worker                    
SUsrvr   SRBroker        3145735    2312    Running           Interactive  2012-02-13 08:14:02  2000-00-00 00:00:00                                                                                           System                  0             Response task             Worker                    
SUsrvr   SRBroker        3145734    2312    Running           Interactive  2012-02-13 08:14:02  2000-00-00 00:00:00                                                                                           System                  0             Task creation task        Worker                    
SUsrvr   SRBroker        3145733    2312    Running           Interactive  2012-02-13 08:14:02  2000-00-00 00:00:00                                                                                           System                  0             Information caching task  Worker                    
SUsrvr   SCBroker        2097154    2324    Running           Background   2012-02-13 08:13:56  2000-00-00 00:00:00                                                                                           System                  0                                       Normal                    

33 rows returned.

