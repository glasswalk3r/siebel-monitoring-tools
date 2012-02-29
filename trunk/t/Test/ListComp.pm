package Test::ListComp;

use Test::Most;
use base 'Test::Class';

sub class { 'Siebel::Srvrmgr::ListParser::Output::ListComp' }

sub startup : Tests(startup => 1) {

    my $test = shift;
    use_ok $test->class;
}

sub constructor : Tests(9) {

    my $test  = shift;
    my $class = $test->class;

    can_ok( $class, 'new' );

    #extended method tests
    can_ok( $class,
        qw(get_fields_pattern get_comp_attribs get_last_server get_servers get_server)
    );

    my @data = <Test::ListComp::DATA>;
    close(Test::ListComp::DATA);

    ok(
        my $comps = $class->new(
            {
                data_type => 'list_comp',
                raw_data  => \@data,
                cmd_line  => 'list comp'
            }
        ),
        '... and the constructor should succeed'
    );

    isa_ok( $comps, $class, '... and the object it returns' );

    is(
        $comps->get_fields_pattern(),
        'A12A19A41A10A14A13A19A18A14A19A18A21A13A11A14A14',
        'fields_patterns is correct'
    );

    my $comp_attribs = [
        qw(CC_NAME CT_ALIAS CG_ALIAS CC_RUNMODE CP_DISP_RUN_STATE CP_NUM_RUN_TASKS CP_MAX_TASKS CP_ACTV_MTS_PROCS CP_MAX_MTS_PROCS CP_START_TIME CP_END_TIME CP_STATUS CC_INCARN_NO CC_DESC_TEXT)
    ];

    is_deeply( $comps->get_comp_attribs(),
        $comp_attribs,
        'get_fields_pattern returns a correct set of attributes' );

    is( $comps->get_last_server(),
        'foobar', 'get_last_server returns the correct server name' );

    is_deeply( $comps->get_servers(), ['foobar'],
        'get_servers returns the correct array reference' );

    my $server_class = 'Siebel::Srvrmgr::ListParser::Output::ListComp::Server';

    isa_ok( $comps->get_server( $comps->get_last_server() ),
        $server_class, "get_last_server returns a $server_class object" );

}

1;

__DATA__
SV_NAME     CC_ALIAS           CC_NAME                                  CT_ALIAS  CG_ALIAS      CC_RUNMODE   CP_DISP_RUN_STATE  CP_NUM_RUN_TASKS  CP_MAX_TASKS  CP_ACTV_MTS_PROCS  CP_MAX_MTS_PROCS  CP_START_TIME        CP_END_TIME  CP_STATUS  CC_INCARN_NO  CC_DESC_TEXT  
----------  -----------------  ---------------------------------------  --------  ------------  -----------  -----------------  ----------------  ------------  -----------------  ----------------  -------------------  -----------  ---------  ------------  ------------  
foobar      ClientAdmin        Client Administration                              System        Background   Ativado            0                 1                                                  2009-09-04 18:31:20                                                      
foobar      CommConfigMgr      Communications Configuration Manager               CommMgmt      Batch        Ativado            0                 20            1                  1                 2009-09-04 18:37:49                                                      
foobar      CommInboundMgr     Communications Inbound Manager                     CommMgmt      Batch        Ativado            0                 20            1                  1                 2009-09-04 18:31:20                                                      
foobar      CommOutboundMgr    Communications Outbound Manager                    CommMgmt      Batch        Ativado            0                 50            1                  1                 2009-09-04 18:37:50                                                      
foobar      CommSessionMgr     Communications Session Manager                     CommMgmt      Batch        Ativado            0                 20            1                  1                 2009-09-04 18:31:20                                                      
foobar      DbXtract           Database Extract                                   Remote        Batch        Ativado            0                 50                                                 2009-09-04 18:31:20                                                      
foobar      EAIObjMgr_ptb      EAI Object Manager (PTB)                           EAI           Interactive  Ativado            0                 20            1                  1                 2009-09-04 18:31:20                                                      
foobar      MailMgr            Email Manager                                      CommMgmt      Background   Ativado            0                 20                                                 2009-09-04 18:31:20                                                      
foobar      EIM                Enterprise Integration Mgr                         EAI           Batch        Ativado            0                 5                                                  2009-09-04 18:31:20                                                      
foobar      FSMSrvr            File System Manager                                System        Batch        Ativado            0                 20            1                  1                 2009-09-04 18:31:20                                                      
foobar      GenNewDb           Generate New Database                              Remote        Batch        Ativado            0                 1                                                  2009-09-04 18:31:20                                                      
foobar      GenTrig            Generate Triggers                                  Workflow      Batch        Ativado            0                 1                                                  2009-09-04 18:31:20                                                      
foobar      PageMgr            Page Manager                                       CommMgmt      Background   Ativado            0                 20                                                 2009-09-04 18:31:20                                                      
foobar      PDbXtract          Parallel Database Extract                          Remote        Batch        Em execução        4                 100           1                  10                2009-09-04 18:37:51                                                      
foobar      ServerMgr          Server Manager                                     System        Interactive  Em execução        1                 20                                                 2009-09-04 18:31:20                                                      
foobar      SRBroker           Server Request Broker                              System        Interactive  Em execução        20                100           1                  1                 2009-09-04 18:37:48                                                      
foobar      SRProc             Server Request Processor                           System        Interactive  Em execução        2                 20            1                  1                 2009-09-04 18:37:45                                                      
foobar      SynchMgr           Synchronization Manager                            Remote        Interactive  Ativado            0                 100           2                  20                2009-09-14 17:25:14                                                      
foobar      TxnMerge           Transaction Merger                                 Remote        Background   Em execução        1                 5                                                  2009-09-14 17:24:52                                                      
foobar      TxnProc            Transaction Processor                              Remote        Background   Em execução        1                 1                                                  2009-09-04 18:31:20                                                      
foobar      TxnRoute           Transaction Router                                 Remote        Background   Em execução        3                 5                                                  2009-09-14 17:24:22                                                      
foobar      UpgKitBldr         Upgrade Kit Builder                                SiebAnywhere  Batch        Ativado            0                 1             1                  1                 2009-09-04 18:37:53                                                      
foobar      WorkActn           Workflow Action Agent                              Workflow      Background   Ativado            0                 5                                                  2009-09-08 11:02:34                                                      
foobar      WorkMon            Workflow Monitor Agent                             Workflow      Background   Em execução        1                 1                                                  2009-09-04 18:31:20                                                      
foobar      WorkMonBISAO       Workflow Monitor Agent BISAO                       Workflow      Background   Em execução        1                 1                                                  2009-09-04 18:31:20                                                      
foobar      WorkMonBudget      Workflow Monitor Agent BISAO Budget Upd            Workflow      Background   Em execução        1                 1                                                  2009-09-08 10:58:41                                                      
foobar      WorkMonMISRMail    Workflow Monitor Agent MI SR Mail                  Workflow      Background   Em execução        1                 1                                                  2009-09-04 18:31:20                                                      
foobar      WorkMonPLUS        Workflow Monitor Agent PLUS                        Workflow      Background   Em execução        1                 1                                                  2009-09-04 18:31:20                                                      
foobar      WfProcBatchMgr     Workflow Process Batch Manager                     Workflow      Batch        Ativado            0                 20            1                  1                 2009-09-08 11:04:41                                                      
foobar      WfProcMgr          Workflow Process Manager                           Workflow      Batch        Ativado            0                 20            1                  1                 2009-09-08 11:03:23                                                      
foobar      ePharmaObjMgr_ptb  ePharma Object Manager (PTB)                       LifeSciences  Interactive  Ativado            0                 60            1                  2                 2009-09-17 17:17:25                                                      

31 rows returned.

