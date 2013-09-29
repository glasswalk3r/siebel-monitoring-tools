package Test::Siebel::Srvrmgr::ListParser::Output::ListComp;

use Test::Most;
use Test::Moose 'has_attribute_ok';
use Hash::Util qw(lock_keys unlock_keys);
use base 'Test::Siebel::Srvrmgr::ListParser::Output';

sub class_attributes : Tests(+3) {

    my $test = shift;

    $test->SUPER::class_attributes();

    foreach my $attrib (qw(last_server comp_attribs servers)) {

        has_attribute_ok( $test->get_output(), $attrib );

    }

}

sub _constructor {

    my $test = shift;
    $test->SUPER::_constructor();
    unlock_keys( %{$test} );
    $test->{last_server} = 'foobar';
    lock_keys( %{$test} );

}

sub get_last_server {

    my $test = shift;

    return $test->{last_server};

}

sub get_servers {

    my $test = shift;
    return [ $test->get_last_server() ];

}

sub class_methods : Tests(+7) {

    my $test = shift;

    $test->SUPER::class_methods();

    can_ok( $test->get_output(),
        qw(get_fields_pattern get_comp_attribs get_last_server get_servers get_server)
    );

    is(
        $test->get_output()->get_fields_pattern(),
        'A12A19A41A10A14A13A19A18A14A19A18A21A13A11A14A14',
        'fields_patterns is correct'
    );

    my $comp_attribs = [
        qw(CC_NAME CT_ALIAS CG_ALIAS CC_RUNMODE CP_DISP_RUN_STATE CP_NUM_RUN_TASKS CP_MAX_TASKS CP_ACTV_MTS_PROCS CP_MAX_MTS_PROCS CP_START_TIME CP_END_TIME CP_STATUS CC_INCARN_NO CC_DESC_TEXT)
    ];

    is_deeply( $test->get_output()->get_comp_attribs(),
        $comp_attribs,
        'get_fields_pattern returns a correct set of attributes' );

    is(
        $test->get_output()->get_last_server(),
        $test->get_last_server(),
        'get_last_server returns the correct server name'
    );

    is_deeply( $test->get_output()->get_servers(),
        $test->get_servers(),
        'get_servers returns the correct array reference' );

    my $server_class = 'Siebel::Srvrmgr::ListParser::Output::ListComp::Server';

    my $server;

    ok(
        $server =
          $test->get_output()
          ->get_server( $test->get_output()->get_last_server() ),
        'get_server returns an object'
    );

  SKIP: {

        skip 'get_server() method failed', 1 unless ( defined($server) );

        isa_ok( $server, $server_class );

    }

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
foobar      WorkMonFoobar      Workflow Monitor Agent Foobar                      Workflow      Background   Executing          1                 1                                                  2009-09-04 18:31:20                                                      
foobar      WorkMonFoobiu      Workflow Monitor Agent Foobiu                      Workflow      Background   Executing          1                 1                                                  2009-09-08 10:58:41                                                      
foobar      WorkMonMyEmails    Workflow Monitor Agent My Emails                   Workflow      Background   Executing          1                 1                                                  2009-09-04 18:31:20                                                      
foobar      WorkMonPLUS        Workflow Monitor Agent PLUS                        Workflow      Background   Executing          1                 1                                                  2009-09-04 18:31:20                                                      
foobar      WfProcBatchMgr     Workflow Process Batch Manager                     Workflow      Batch        Activated          0                 20            1                  1                 2009-09-08 11:04:41                                                      
foobar      WfProcMgr          Workflow Process Manager                           Workflow      Batch        Activated          0                 20            1                  1                 2009-09-08 11:03:23                                                      
foobar      ePharmaObjMgr_ptb  ePharma Object Manager (PTB)                       LifeSciences  Interactive  Activated          0                 60            1                  2                 2009-09-17 17:17:25                                                      

31 rows returned.

