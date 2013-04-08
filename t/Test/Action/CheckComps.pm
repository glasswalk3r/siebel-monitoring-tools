package Test::Action::CheckComps;

use base 'Test::Class';
use Test::Most;
use Siebel::Srvrmgr::ListParser;
use Siebel::Srvrmgr::Daemon::Action::CheckComps;
use Siebel::Srvrmgr::ListParser::Output::ListComp::Server;
use Test::Action::CheckComps::Server;
use Test::Action::CheckComps::Component;

sub class { 'Siebel::Srvrmgr::Daemon::Action::CheckComps' }

sub startup : Tests(startup => 1) {

    my $test = shift;
    use_ok $test->class;

}

sub constructor : Tests(5) {

    my $test  = shift;
    my $class = $test->class;

    can_ok( $class, qw(new do) );

    my $stash = Siebel::Srvrmgr::Daemon::ActionStash->instance();

	# applying roles as expected by Siebel::Srvrmgr::Daemon::Action::CheckComps
    my $comp1 = Test::Action::CheckComps::Component->new(
        {
            name           => 'SynchMgr',
            description    => 'foobar',
            componentGroup => 'foobar',
            OKStatus       => 'Running',
            criticality    => 5
        }
    );
    my $comp2 = Test::Action::CheckComps::Component->new(
        {
            name           => 'WfProcMgr',
            description    => 'foobar',
            componentGroup => 'foobar',
            OKStatus       => 'Running',
            criticality    => 5
        }
    );

    my $server1 = Test::Action::CheckComps::Server->new(
        { name => 'sieb_foobar', components => [ $comp1, $comp2 ] } );
    my $server2 = Test::Action::CheckComps::Server->new(
        { name => 'foobar', components => [ $comp1, $comp2 ] } );

    my $action;

    ok(
        $action = $class->new(
            {
                parser => Siebel::Srvrmgr::ListParser->new(),
                params => [$server1]
            }
        ),
        'the constructor should succeed'
    );

    # mocking the returned data from srvrmgr
    my @input_data = <Test::Action::CheckComps::DATA>;
    close(Test::Action::CheckComps::DATA);

    ok( $action->do( \@input_data ), 'do() can process the input data' );

    # data expected to be returned from the stash
    my $expected_data = {
        'sieb_foobar' => {
            'SynchMgr'  => 0,
            'WfProcMgr' => 0
        }
    };

    is_deeply( $stash->get_stash(), $expected_data,
        'data returned by the stash is the expected one' );

    my $other_action = $class->new(
        {
            parser => Siebel::Srvrmgr::ListParser->new(),
            params => [$server2]
        }
    );

    dies_ok(
        sub { $other_action->do( \@input_data ) },
        'do method must die because the expected server will not be available'
    );

}

1;

__DATA__
srvrmgr> list comp

SV_NAME     CC_ALIAS              CC_NAME                               CT_ALIAS  CG_ALIAS      CC_RUNMODE   CP_DISP_RUN_STATE  CP_NUM_RUN_TASKS  CP_MAX_TASKS  CP_ACTV_MTS_PROCS  CP_MAX_MTS_PROCS  CP_START_TIME        CP_END_TIME          CP_STATUS  CC_INCARN_NO  CC_DESC_TEXT  
-----------  --------------------  ------------------------------------  --------  ------------  -----------  -----------------  ----------------  ------------  -----------------  ----------------  -------------------  -------------------  ---------  ------------  ------------  
sieb_foobar  ClientAdmin           Client Administration                           System        Background   Activated          0                 1                                                  2012-02-18 17:11:56                                                              
sieb_foobar  CommConfigMgr         Communications Configuration Manager            CommMgmt      Batch        Activated          0                 20            1                  1                 2012-02-18 17:11:56                                                              
sieb_foobar  CommInboundMgr        Communications Inbound Manager                  CommMgmt      Batch        Activated          0                 20            1                  1                 2012-02-18 17:11:56                                                              
sieb_foobar  CommOutboundMgr       Communications Outbound Manager                 CommMgmt      Batch        Activated          0                 50            1                  1                 2012-02-18 17:11:56                                                              
sieb_foobar  CommSessionMgr        Communications Session Manager                  CommMgmt      Batch        Activated          0                 20            1                  1                 2012-02-18 17:11:56                                                              
sieb_foobar  DbXtract              Database Extract                                Remote        Batch        Activated          0                 10                                                 2012-02-18 17:11:56                                                              
sieb_foobar  EAIObjMgr_ptb         EAI Object Manager (PTB)                        EAI           Interactive  Activated          0                 20            1                  1                 2012-02-18 17:11:56                                                              
sieb_foobar  MailMgr               Email Manager                                   CommMgmt      Background   Activated          0                 20                                                 2012-02-18 17:11:56                                                              
sieb_foobar  EIM                   Enterprise Integration Mgr                      EAI           Batch        Activated          0                 10                                                 2012-02-18 17:11:56                                                              
sieb_foobar  FSMSrvr               File System Manager                             System        Batch        Activated          0                 20            1                  1                 2012-02-18 17:11:56                                                              
sieb_foobar  GenNewDb              Generate New Database                           Remote        Batch        Activated          0                 1                                                  2012-02-18 17:11:56                                                              
sieb_foobar  GenTrig               Generate Triggers                               Workflow      Batch        Activated          0                 1                                                  2012-02-18 17:11:56                                                              
sieb_foobar  PageMgr               Page Manager                                    CommMgmt      Background   Activated          0                 20                                                 2012-02-18 17:11:56                                                              
sieb_foobar  PDbXtract             Parallel Database Extract                       Remote        Batch        Running            4                 10            1                  1                 2012-02-18 17:11:56                                                              
sieb_foobar  ServerMgr             Server Manager                                  System        Interactive  Running            1                 20                                                 2012-02-18 17:11:56                                                              
sieb_foobar  SRBroker              Server Request Broker                           System        Interactive  Running            10                100           1                  1                 2012-02-18 17:11:56                                                              
sieb_foobar  SRProc                Server Request Processor                        System        Interactive  Running            2                 20            1                  1                 2012-02-18 17:11:56                                                              
sieb_foobar  SynchMgr              Synchronization Manager                         Remote        Interactive  Activated          0                 100           1                  1                 2012-02-18 17:11:56                                                              
sieb_foobar  TxnMerge              Transaction Merger                              Remote        Background   Running            1                 10                                                 2012-02-18 17:11:56                                                              
sieb_foobar  TxnProc               Transaction Processor                           Remote        Background   Running            1                 1                                                  2012-02-18 17:11:56                                                              
sieb_foobar  TxnRoute              Transaction Router                              Remote        Background   Running            3                 10                                                 2012-02-18 17:11:56                                                              
sieb_foobar  UpgKitBldr            Upgrade Kit Builder                             SiebAnywhere  Batch        Activated          0                 1             1                  1                 2012-02-18 17:11:56                                                              
sieb_foobar  WorkActn              Workflow Action Agent                           Workflow      Background   Activated          0                 5                                                  2012-02-18 17:11:56                                                              
sieb_foobar  WorkMon               Workflow Monitor Agent                          Workflow      Background   Running            1                 1                                                  2012-02-18 17:11:56                                                              
sieb_foobar  WfProcBatchMgr        Workflow Process Batch Manager                  Workflow      Batch        Activated          0                 20            1                  1                 2012-02-18 17:11:56                                                              
sieb_foobar  WfProcMgr             Workflow Process Manager                        Workflow      Batch        Activated          0                 20            1                  1                 2012-02-18 17:11:56                                                              
sieb_foobar  ePharmaObjMgr_ptb     ePharma Object Manager (PTB)                    LifeSciences  Interactive  Running            3                 60            1                  2                 2012-02-18 17:11:56                                                              

51 rows returned.

