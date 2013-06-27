package Test::Siebel::Srvrmgr::ListParser::Output::ListComp;

use Test::Most;
use Test::Moose 'has_attribute_ok';
use base 'Test::Siebel::Srvrmgr';

sub _constructor : Tests(+2) {

    my $test = shift;

    ok(
        $test->{comps} = $test->class()->new(
            {
                data_type => 'list_comp',
                raw_data  => $test->get_my_data(),
                cmd_line  => 'list comp'
            }
        ),
        '... and the constructor should succeed'
    );

    isa_ok( $test->{comps}, $test->class() );

}

sub class_attributes : Tests(+3) {

    my $test = shift;

    foreach my $attrib (qw(last_server comps_attribs servers)) {

        has_attribute_ok( $test->{comps}, $attrib );

    }

}

sub class_methods : Tests(+6) {

    my $test = shift;

    can_ok( $test->{comps},
        qw(get_fields_pattern get_comp_attribs get_last_server get_servers get_server)
    );

    is(
        $test->{comps}->get_fields_pattern(),
        'A12A19A41A10A14A13A19A18A14A19A18A21A13A11A14A14',
        'fields_patterns is correct'
    );

    my $comp_attribs = [
        qw(CC_NAME CT_ALIAS CG_ALIAS CC_RUNMODE CP_DISP_RUN_STATE CP_NUM_RUN_TASKS CP_MAX_TASKS CP_ACTV_MTS_PROCS CP_MAX_MTS_PROCS CP_START_TIME CP_END_TIME CP_STATUS CC_INCARN_NO CC_DESC_TEXT)
    ];

    is_deeply( $test->{comps}->get_comp_attribs(),
        $comp_attribs,
        'get_fields_pattern returns a correct set of attributes' );

    is( $test->{comps}->get_last_server(),
        'foobar', 'get_last_server returns the correct server name' );

    is_deeply( $test->{comps}->get_servers(),
        ['foobar'], 'get_servers returns the correct array reference' );

    my $server_class = 'Siebel::Srvrmgr::ListParser::Output::ListComp::Server';

    isa_ok( $test->{comps}->get_server( $test->{comps}->get_last_server() ),
        $server_class, "get_last_server returns a $server_class object" );

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
foobar      PDbXtract          Parallel Database Extract                          Remote        Batch        Executing          4                 100           1                  10                2009-09-04 18:37:51                                                      
foobar      ServerMgr          Server Manager                                     System        Interactive  Executing          1                 20                                                 2009-09-04 18:31:20                                                      
foobar      SRBroker           Server Request Broker                              System        Interactive  Executing          20                100           1                  1                 2009-09-04 18:37:48                                                      
foobar      SRProc             Server Request Processor                           System        Interactive  Executing          2                 20            1                  1                 2009-09-04 18:37:45                                                      
foobar      SynchMgr           Synchronization Manager                            Remote        Interactive  Activated          0                 100           2                  20                2009-09-14 17:25:14                                                      
foobar      TxnMerge           Transaction Merger                                 Remote        Background   Executing          1                 5                                                  2009-09-14 17:24:52                                                      
foobar      TxnProc            Transaction Processor                              Remote        Background   Executing          1                 1                                                  2009-09-04 18:31:20                                                      
foobar      TxnRoute           Transaction Router                                 Remote        Background   Executing          3                 5                                                  2009-09-14 17:24:22                                                      
foobar      UpgKitBldr         Upgrade Kit Builder                                SiebAnywhere  Batch        Executing          0                 1             1                  1                 2009-09-04 18:37:53                                                      
foobar      WorkActn           Workflow Action Agent                              Workflow      Background   Activated          0                 5                                                  2009-09-08 11:02:34                                                      
foobar      WorkMon            Workflow Monitor Agent                             Workflow      Background   Executing          1                 1                                                  2009-09-04 18:31:20                                                      
foobar      WorkMonBISAO       Workflow Monitor Agent BISAO                       Workflow      Background   Executing          1                 1                                                  2009-09-04 18:31:20                                                      
foobar      WorkMonBudget      Workflow Monitor Agent BISAO Budget Upd            Workflow      Background   Executing          1                 1                                                  2009-09-08 10:58:41                                                      
foobar      WorkMonMISRMail    Workflow Monitor Agent MI SR Mail                  Workflow      Background   Executing          1                 1                                                  2009-09-04 18:31:20                                                      
foobar      WorkMonPLUS        Workflow Monitor Agent PLUS                        Workflow      Background   Executing          1                 1                                                  2009-09-04 18:31:20                                                      
foobar      WfProcBatchMgr     Workflow Process Batch Manager                     Workflow      Batch        Activated          0                 20            1                  1                 2009-09-08 11:04:41                                                      
foobar      WfProcMgr          Workflow Process Manager                           Workflow      Batch        Activated          0                 20            1                  1                 2009-09-08 11:03:23                                                      
foobar      ePharmaObjMgr_ptb  ePharma Object Manager (PTB)                       LifeSciences  Interactive  Activated          0                 60            1                  2                 2009-09-17 17:17:25                                                      

31 rows returned.

