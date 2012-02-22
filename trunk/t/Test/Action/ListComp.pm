package Test::Action::ListComp;

use base 'Test::Class';
use Test::Pod::Coverage;
use Test::Most;
use Siebel::Srvrmgr::ListParser;
use Siebel::Srvrmgr::ListParser::Output::ListComp::Server;

sub class { 'Siebel::Srvrmgr::Daemon::Action::ListComps' }

sub startup : Tests(startup => 1) {
    my $test = shift;
    use_ok $test->class;
}

sub constructor : Tests(7) {

    my $test  = shift;
    my $class = $test->class;

    can_ok( $class,
        qw(new get_params get_parser get_params do get_dump_file set_dump_file)
    );

    my $file = 'list_comp_def.storable';

    my $action;

    ok(
        $action = $class->new(
            {
                parser =>
                  Siebel::Srvrmgr::ListParser->new( { is_warn_enabled => 1 } ),
                params => [$file]
            }
        ),
        'the constructor should suceed'
    );

    is( $action->get_dump_file(),
        $file, 'get_dump_file returns the correct string' );

    pod_coverage_ok( $class, "$class is Pod covered" );

    ok( $action->set_dump_file($file), 'set_dump_file works' );

    my @data = <Test::Action::ListComp::DATA>;
    close(Test::Action::ListComp::DATA);

    ok( $action->do( \@data ), 'do methods works fine' );

    $file .= '_SUsrvr';

    my $server =
      Siebel::Srvrmgr::ListParser::Output::ListComp::Server->load($file);

    isa_ok(
        $server,
        'Siebel::Srvrmgr::ListParser::Output::ListComp::Server',
        'an server object can be recovered from file with serialized data'
    );

    unlink($file) or die "Cannot remove $file: $!\n";

}

1;

__DATA__
srvrmgr:SUsrvr> list comp

SV_NAME  CC_ALIAS             CC_NAME                                      CT_ALIAS         CG_ALIAS    CC_RUNMODE   CP_DISP_RUN_STATE  CP_STARTMODE  CP_NUM_RUN_  CP_MAX_TASK  CP_ACTV_MTS  CP_MAX_MTS_  CP_START_TIME        CP_END_TIME  CC_INCARN_NO  CC_DESC_TEXT  
-------  -------------------  -------------------------------------------  ---------------  ----------  -----------  -----------------  ------------  -----------  -----------  -----------  -----------  -------------------  -----------  ------------  ------------  
SUsrvr   AsgnSrvr             Assignment Manager                           AsgnSrvr         AsgnMgmt    Batch        Online             Auto          0            20           1            1            2012-02-13 08:14:11                                           
SUsrvr   AsgnBatch            Batch Assignment                             AsgnBatch        AsgnMgmt    Batch        Online             Auto          0            20                                     2012-02-13 08:14:11                                           
SUsrvr   BusIntBatchMgr       Business Integration Batch Manager           BusSvcMgr        EAI         Batch        Online             Auto          0            20           1            1            2012-02-13 08:14:11                                           
SUsrvr   BusIntMgr            Business Integration Manager                 BusSvcMgr        EAI         Batch        Online             Auto          0            20           1            1            2012-02-13 08:14:11                                           
SUsrvr   SCCObjMgr_enu        Call Center Object Manager (ENU)             AppObjMgr        CallCenter  Interactive  Online             Auto          0            20           1            1            2012-02-13 08:14:11                                           
SUsrvr   SCCObjMgr_esn        Call Center Object Manager (ESN)             AppObjMgr        CallCenter  Interactive  Online             Auto          0            20           1            1            2012-02-13 08:14:11                                           
SUsrvr   CustomAppObjMgr_enu  Custom Application Object Manager (ENU)      CustomAppObjMgr  EAI         Interactive  Online             Auto          0            20           1            1            2012-02-13 08:14:11                                           
SUsrvr   CustomAppObjMgr_esn  Custom Application Object Manager (ESN)      CustomAppObjMgr  EAI         Interactive  Online             Auto          0            20           1            1            2012-02-13 08:14:11                                           
SUsrvr   DbXtract             Database Extract                             DbXtract         Remote      Batch        Online             Auto          0            10                                     2012-02-13 08:14:11                                           
SUsrvr   EAIObjMgr_enu        EAI Object Manager (ENU)                     EAIObjMgr        EAI         Interactive  Online             Auto          0            20           1            1            2012-02-13 08:14:11                                           
SUsrvr   EAIObjMgr_esn        EAI Object Manager (ESN)                     EAIObjMgr        EAI         Interactive  Online             Auto          0            20           1            1            2012-02-13 08:14:11                                           
SUsrvr   EIM                  Enterprise Integration Mgr                   EIM              EAI         Batch        Online             Auto          0            5                                      2012-02-13 08:14:11                                           
SUsrvr   FSMSrvr              File System Manager                          FSMSrvr          SystemAux   Batch        Online             Auto          0            20           1            1            2012-02-13 08:14:06                                           
SUsrvr   GenNewDb             Generate New Database                        GenNewDb         Remote      Batch        Online             Auto          0            1                                      2012-02-13 08:14:11                                           
SUsrvr   GenTrig              Generate Triggers                            GenTrig          Workflow    Batch        Online             Auto          0            1                                      2012-02-13 08:14:11                                           
SUsrvr   JMSReceiver          JMS Receiver                                 EAIRcvr          EAI         Background   Online             Auto          0            20                                     2012-02-13 08:14:11                                           
SUsrvr   MqSeriesAMIRcvr      MQSeries AMI Receiver                        EAIRcvr          EAI         Background   Online             Auto          0            20                                     2012-02-13 08:14:11                                           
SUsrvr   MqSeriesSrvRcvr      MQSeries Server Receiver                     EAIRcvr          EAI         Background   Online             Auto          0            20                                     2012-02-13 08:14:11                                           
SUsrvr   MSMQRcvr             MSMQ Receiver                                EAIRcvr          EAI         Background   Online             Auto          0            20                                     2012-02-13 08:14:11                                           
SUsrvr   PDbXtract            Parallel Database Extract                    DbXtract         Remote      Batch        Online             Auto          0            10           1            1            2012-02-13 08:14:11                                           
SUsrvr   RepAgent             Replication Agent                            RepAgent         Remote      Background   Online             Auto          0            1                                      2012-02-13 08:14:11                                           
SUsrvr   SBRWorkActn          SBR Workflow Action Agent                    WorkActn         Workflow    Background   Running            Auto          1            1                                      2012-02-13 08:14:11                                           
SUsrvr   SBRWorkMon           SBR Workflow Monitor Agent                   WorkMon          Workflow    Background   Running            Auto          1            1                                      2012-02-13 08:14:11                                           
SUsrvr   SMQReceiver          SMQ Receiver                                 EAIRcvr          EAI         Background   Online             Auto          0            20                                     2012-02-13 08:14:11                                           
SUsrvr   ServerMgr            Server Manager                               ServerMgr        System      Interactive  Running            Auto          1            20                                     2012-02-13 08:13:56                                           
SUsrvr   SRBroker             Server Request Broker                        ReqBroker        System      Interactive  Running            Auto          21           100          1            1            2012-02-13 08:13:56                                           
SUsrvr   SRProc               Server Request Processor                     SRProc           SystemAux   Interactive  Running            Auto          2            20           1            1            2012-02-13 08:14:06                                           
SUsrvr   SvrTblCleanup        Server Tables Cleanup                        BusSvcMgr        SystemAux   Background   Running            Auto          1            1                                      2012-02-13 08:14:06                                           
SUsrvr   SvrTaskPersist       Server Task Persistance                      BusSvcMgr        SystemAux   Background   Running            Auto          1            1                                      2012-02-13 08:14:06                                           
SUsrvr   AdminNotify          Siebel Administrator Notification Component  AdminNotify      SystemAux   Batch        Online             Auto          0            10           1            1            2012-02-13 08:14:06                                           
SUsrvr   SCBroker             Siebel Connection Broker                     SCBroker         System      Background   Running            Auto          1            1                                      2012-02-13 08:13:56                                           
SUsrvr   SynchMgr             Synchronization Manager                      SynchMgr         Remote      Interactive  Online             Auto          0            100          1            1            2012-02-13 08:14:11                                           
SUsrvr   TaskLogCleanup       Task Log Cleanup                             BusSvcMgr        TaskUI      Background   Running            Auto          1            1                                      2012-02-13 08:14:11                                           
SUsrvr   TxnMerge             Transaction Merger                           TxnMerge         Remote      Background   Running            Auto          1            10                                     2012-02-13 08:14:11                                           
SUsrvr   TxnProc              Transaction Processor                        TxnProc          Remote      Background   Running            Auto          1            1                                      2012-02-13 08:14:11                                           
SUsrvr   TxnRoute             Transaction Router                           TxnRoute         Remote      Background   Running            Auto          1            10                                     2012-02-13 08:14:11                                           
SUsrvr   WorkActn             Workflow Action Agent                        WorkActn         Workflow    Background   Online             Auto          0            5                                      2012-02-13 08:14:11                                           
SUsrvr   WorkMon              Workflow Monitor Agent                       WorkMon          Workflow    Background   Online             Auto          0            5                                      2012-02-13 08:14:11                                           
SUsrvr   WfProcBatchMgr       Workflow Process Batch Manager               BusSvcMgr        Workflow    Batch        Online             Auto          0            20           1            1            2012-02-13 08:14:11                                           
SUsrvr   WfProcMgr            Workflow Process Manager                     BusSvcMgr        Workflow    Batch        Online             Auto          0            20           1            1            2012-02-13 08:14:11                                           
SUsrvr   WfRecvMgr            Workflow Recovery Manager                    BusSvcMgr        Workflow    Batch        Online             Auto          0            20           1            1            2012-02-13 08:14:11                                           
SUsrvr   eServiceObjMgr_enu   eService Object Manager (ENU)                AppObjMgr        CallCenter  Interactive  Online             Auto          0            20           1            1            2012-02-13 08:14:11                                           
SUsrvr   eServiceObjMgr_esn   eService Object Manager (ESN)                AppObjMgr        CallCenter  Interactive  Online             Auto          0            20           1            1            2012-02-13 08:14:11                                           

43 rows returned.

