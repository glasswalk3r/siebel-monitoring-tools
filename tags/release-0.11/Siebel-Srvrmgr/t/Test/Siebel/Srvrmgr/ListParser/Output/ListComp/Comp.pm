package Test::Siebel::Srvrmgr::ListParser::Output::ListComp::Comp;

use Test::Most;
use Test::Moose 'has_attribute_ok';
use base 'Test::Siebel::Srvrmgr';
use Siebel::Srvrmgr::ListParser::Output::ListComp;

sub _constructor : Tests(2) {

    my $test = shift;

    my $list_comp = Siebel::Srvrmgr::ListParser::Output::ListComp->new(
        {
            data_type => 'list_comp',
            raw_data  => $test->get_my_data(),
            cmd_line  => 'list comp'
        }
    );

    my $server = $list_comp->get_server('foobar');

    my $alias = 'SRProc';

    ok(
        $test->{comp} = $test->class()->new(
            { data => $server->get_data()->{$alias}, cc_alias => $alias }
        ),
        'the constructor should succeed'
    );

    isa_ok( $test->{comp}, $test->class(),
        'the object is a instance of the correct class' );

}

sub class_attributes : Tests(17) {

    my $test = shift;

    my @attribs = (
        'data',              'cc_alias',
        'cc_name',           'ct_alias',
        'ct_name',           'cg_alias',
        'cc_runmode',        'cp_disp_run_state',
        'cp_num_run_tasks',  'cp_max_tasks',
        'cp_actv_mts_procs', 'cp_max_mts_procs',
        'cp_start_time',     'cp_end_time',
        'cp_status',         'cc_incarn_no',
        'cc_desc_text'
    );

    foreach my $attrib (@attribs) {

        has_attribute_ok( $test->{comp}, $attrib );

    }
}

sub class_methods : Tests(15) {

    my $test = shift;

    can_ok( $test->{comp},
        qw(get_data cc_alias cc_name ct_alias ct_name cg_alias cc_runmode cp_disp_run_state cp_num_run_tasks cp_max_tasks cp_actv_mts_procs cp_max_mts_procs cp_start_time cp_end_time cp_status cc_incarn_no cc_desc_text)
    );

    is( $test->{comp}->cp_num_run_tasks(),
        2, 'cp_num_run_tasks returns the correct value' );
    is( $test->{comp}->cc_incarn_no(),
        0, 'cc_incarn_no returns the correct value' );
    is(
        $test->{comp}->cc_name(),
        'Server Request Processor',
        ' returns the correct value'
    );
    is( $test->{comp}->ct_alias(), '',       ' returns the correct value' );
    is( $test->{comp}->cg_alias(), 'System', ' returns the correct value' );
    is( $test->{comp}->cc_runmode(),
        'Interactive', ' returns the correct value' );
    is( $test->{comp}->cp_disp_run_state(),
        'Running', ' returns the correct value' );
    is( $test->{comp}->cp_max_tasks(),
        20, 'cp_max_tasks returns the correct value' );
    is( $test->{comp}->cp_actv_mts_procs(),
        1, 'cp_actv_mts_procs returns the correct value' );
    is( $test->{comp}->cp_max_mts_procs(),
        1, 'cp_max_mts_procs returns the correct value' );
    is(
        $test->{comp}->cp_start_time(),
        '2009-09-04 18:37:45',
        'cp_start_time returns the correct value'
    );
    is( $test->{comp}->cp_end_time(),
        '', 'cp_end_time returns the correct value' );
    is( $test->{comp}->cp_status(), '', 'cp_status returns the correct value' );
    is( $test->{comp}->cc_desc_text(),
        '', 'cc_desc_text returns the correct value' );

}

1;

__DATA__
SV_NAME     CC_ALIAS           CC_NAME                                  CT_ALIAS  CG_ALIAS      CC_RUNMODE   CP_DISP_RUN_STATE  CP_NUM_RUN_TASKS  CP_MAX_TASKS  CP_ACTV_MTS_PROCS  CP_MAX_MTS_PROCS  CP_START_TIME        CP_END_TIME  CP_STATUS  CC_INCARN_NO  CC_DESC_TEXT  
----------  -----------------  ---------------------------------------  --------  ------------  -----------  -----------------  ----------------  ------------  -----------------  ----------------  -------------------  -----------  ---------  ------------  ------------  
foobar      ClientAdmin        Client Administration                              System        Background   Activated          0                 1                                                  2009-09-04 18:31:20                                                      
foobar      CommConfigMgr      Communications Configuration Manager               CommMgmt      Batch        Activated          0                 20            1                  1                 2009-09-04 18:37:49                                                      
foobar      CommInboundMgr     Communications Inbound Manager                     CommMgmt      Batch        Activated          0                 20            1                  1                 2009-09-04 18:31:20                                                      
foobar      CommOutboundMgr    Communications Outbound Manager                    CommMgmt      Batch        Activated          0                 50            1                  1                 2009-09-04 18:37:50                                                      
foobar      CommSessionMgr     Communications Session Manager                     CommMgmt      Batch        Activated          0                 20            1                  1                 2009-09-04 18:31:20                                                      
foobar      DbXtract           Database Extract                                   Remote        Batch        Activated          0                 50                                                 2009-09-04 18:31:20                                                      
foobar      EAIObjMgr_ptb      EAI Object Manager (PTB)                           EAI           Interactive  Activated          0                 20            1                  1                 2009-09-04 18:31:20                                                      
foobar      MailMgr            Email Manager                                      CommMgmt      Background   Activated          0                 20                                                 2009-09-04 18:31:20                                                      
foobar      EIM                Enterprise Integration Mgr                         EAI           Batch        Activated          0                 5                                                  2009-09-04 18:31:20                                                      
foobar      FSMSrvr            File System Manager                                System        Batch        Activated          0                 20            1                  1                 2009-09-04 18:31:20                                                      
foobar      GenNewDb           Generate New Database                              Remote        Batch        Activated          0                 1                                                  2009-09-04 18:31:20                                                      
foobar      GenTrig            Generate Triggers                                  Workflow      Batch        Activated          0                 1                                                  2009-09-04 18:31:20                                                      
foobar      PageMgr            Page Manager                                       CommMgmt      Background   Activated          0                 20                                                 2009-09-04 18:31:20                                                      
foobar      PDbXtract          Parallel Database Extract                          Remote        Batch        Running            4                 100           1                  10                2009-09-04 18:37:51                                                      
foobar      ServerMgr          Server Manager                                     System        Interactive  Running            1                 20                                                 2009-09-04 18:31:20                                                      
foobar      SRBroker           Server Request Broker                              System        Interactive  Running            20                100           1                  1                 2009-09-04 18:37:48                                                      
foobar      SRProc             Server Request Processor                           System        Interactive  Running            2                 20            1                  1                 2009-09-04 18:37:45                                                      
foobar      SynchMgr           Synchronization Manager                            Remote        Interactive  Activated          0                 100           2                  20                2009-09-14 17:25:14                                                      
foobar      TxnMerge           Transaction Merger                                 Remote        Background   Running            1                 5                                                  2009-09-14 17:24:52                                                      
foobar      TxnProc            Transaction Processor                              Remote        Background   Running            1                 1                                                  2009-09-04 18:31:20                                                      
foobar      TxnRoute           Transaction Router                                 Remote        Background   Running            3                 5                                                  2009-09-14 17:24:22                                                      
foobar      UpgKitBldr         Upgrade Kit Builder                                SiebAnywhere  Batch        Activated          0                 1             1                  1                 2009-09-04 18:37:53                                                      
foobar      WorkActn           Workflow Action Agent                              Workflow      Background   Activated          0                 5                                                  2009-09-08 11:02:34                                                      
foobar      WorkMon            Workflow Monitor Agent                             Workflow      Background   Running            1                 1                                                  2009-09-04 18:31:20                                                      
foobar      WorkMonFOOBA       Workflow Monitor Agent FOOBAR                      Workflow      Background   Running            1                 1                                                  2009-09-04 18:31:20                                                      
foobar      WorkMonBudget      Workflow Monitor Agent Budget                      Workflow      Background   Running            1                 1                                                  2009-09-08 10:58:41                                                      
foobar      WorkMonMyEmail     Workflow Monitor Agent My Email                    Workflow      Background   Running            1                 1                                                  2009-09-04 18:31:20                                                      
foobar      WorkMonPLUS        Workflow Monitor Agent PLUS                        Workflow      Background   Running            1                 1                                                  2009-09-04 18:31:20                                                      
foobar      WfProcBatchMgr     Workflow Process Batch Manager                     Workflow      Batch        Activated          0                 20            1                  1                 2009-09-08 11:04:41                                                      
foobar      WfProcMgr          Workflow Process Manager                           Workflow      Batch        Activated          0                 20            1                  1                 2009-09-08 11:03:23                                                      
foobar      ePharmaObjMgr_ptb  ePharma Object Manager (PTB)                       LifeSciences  Interactive  Activated          0                 60            1                  2                 2009-09-17 17:17:25                                                      

31 rows returned.

