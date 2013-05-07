package Test::Server;

use Test::Most;
use Test::Moose qw(has_attribute_ok);
use base 'Test::Class';
use Siebel::Srvrmgr::ListParser::Output::ListComp;

sub class { 'Siebel::Srvrmgr::ListParser::Output::ListComp::Server' }

sub startup : Tests(startup => 1) {

    my $test = shift;
    use_ok $test->class;
}

sub constructor : Tests(10) {

    my $test  = shift;
    my $class = $test->class;

    can_ok( $class, 'new' );

    #extended method tests
    can_ok( $class,
        qw(get_data get_name load store get_comps get_comp get_comp_data) );

    my @data = <Test::Server::DATA>;
    close(Test::Server::DATA);

    my $list_comp = Siebel::Srvrmgr::ListParser::Output::ListComp->new(
        {
            data_type => 'list_comp',
            raw_data  => \@data,
            cmd_line  => 'list comp'
        }
    );

    ok(
        my $server = $list_comp->get_server('foobar'),
        '... and the constructor should succeed'
    );

    has_attribute_ok( $server, 'name' );
    has_attribute_ok( $server, 'data' );

    isa_ok( $server, $class, '... and the object it returns' );

    is( $server->get_name(), 'foobar', 'get_name returns the correct value' );

    isa_ok(
        $server->get_comp('ClientAdmin'),
        'Siebel::Srvrmgr::ListParser::Output::ListComp::Comp',
        'get_comp returns a Comp object'
    );

    isa_ok( $server->get_comps(), 'ARRAY',
        'get_comps returns an array reference' );

    isa_ok( $server->get_comp_data('EIM'),
        'HASH', 'get_comp_data returns an hash reference' );

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
foobar      WorkMonBISAO       Workflow Monitor Agent BISAO                       Workflow      Background   Running            1                 1                                                  2009-09-04 18:31:20                                                      
foobar      WorkMonBudget      Workflow Monitor Agent BISAO Budget Upd            Workflow      Background   Running            1                 1                                                  2009-09-08 10:58:41                                                      
foobar      WorkMonMISRMail    Workflow Monitor Agent MI SR Mail                  Workflow      Background   Running            1                 1                                                  2009-09-04 18:31:20                                                      
foobar      WorkMonPLUS        Workflow Monitor Agent PLUS                        Workflow      Background   Running            1                 1                                                  2009-09-04 18:31:20                                                      
foobar      WfProcBatchMgr     Workflow Process Batch Manager                     Workflow      Batch        Activated          0                 20            1                  1                 2009-09-08 11:04:41                                                      
foobar      WfProcMgr          Workflow Process Manager                           Workflow      Batch        Activated          0                 20            1                  1                 2009-09-08 11:03:23                                                      
foobar      ePharmaObjMgr_ptb  ePharma Object Manager (PTB)                       LifeSciences  Interactive  Activated          0                 60            1                  2                 2009-09-17 17:17:25                                                      

31 rows returned.

