package Test::Siebel::Srvrmgr::Daemon::Action::CheckComps;

use base qw(Test::Siebel::Srvrmgr::Daemon::Action);
use Test::Most;
use Siebel::Srvrmgr::ListParser;
use Siebel::Srvrmgr::Daemon::Action::CheckComps;
use Siebel::Srvrmgr::ListParser::Output::ListComp::Server;
use Test::Siebel::Srvrmgr::Daemon::Action::CheckComps::Server;
use Test::Siebel::Srvrmgr::Daemon::Action::CheckComps::Component;

# must override parent method
sub before : Test(setup) {

    my $test = shift;

    # applying roles as expected by Siebel::Srvrmgr::Daemon::Action::CheckComps
    my $comp1 =
      Test::Siebel::Srvrmgr::Daemon::Action::CheckComps::Component->new(
        {
            alias          => 'SynchMgr',
            description    => 'foobar',
            componentGroup => 'foobar',
            OKStatus       => 'Running',
            criticality    => 5
        }
      );
    my $comp2 =
      Test::Siebel::Srvrmgr::Daemon::Action::CheckComps::Component->new(
        {
            alias          => 'WfProcMgr',
            description    => 'foobar',
            componentGroup => 'foobar',
            OKStatus       => 'Running',
            criticality    => 5
        }
      );

    # should be able to reuse the same parser if there is no concurrency
    $test->{parser} = Siebel::Srvrmgr::ListParser->new();

    $test->{action} = $test->class()->new(
        {
            parser => $test->{parser},
            params => [
                Test::Siebel::Srvrmgr::Daemon::Action::CheckComps::Server->new(
                    {
                        name       => 'sieb_foobar',
                        components => [ $comp1, $comp2 ]
                    }
                )
            ]
        }
    );

    $test->{action2} = $test->class()->new(
        {
            parser => $test->{parser},
            params => [
                Test::Siebel::Srvrmgr::Daemon::Action::CheckComps::Server->new(
                    { name => 'foobar', components => [ $comp1, $comp2 ] }
                )
            ]
        }
    );

}

sub constructor : Tests(+2) {

    my $test = shift;

    ok( $test->{action2}, 'the other constructor should succeed' );
    isa_ok( $test->{action2}, $test->class() );

}

sub class_methods : Tests(+2) {

    my $test = shift;

# :WORKAROUND:28-10-2013:arfreitas: parse() from Siebel::Srvrmgr::ListParser will automatically clean the array reference when it's finished
    my @backup = $test->get_my_data();
    $test->SUPER::class_methods();
    $test->set_my_data( \@backup );

    dies_ok(
        sub { $test->{action2}->do( $test->get_my_data() ) },
        'do method must die because the expected server will not be available'
    );

    my $stash = Siebel::Srvrmgr::Daemon::ActionStash->instance();

    # data expected to be returned from the stash
    is_deeply(
        $stash->shift_stash(),
        {
            'sieb_foobar' => {
                'SynchMgr'  => 0,
                'WfProcMgr' => 0
            }
        },
        'data returned by the stash is the expected one'
    );

}

1;

__DATA__
srvrmgr> list comp

SV_NAME      CC_ALIAS              CC_NAME                               CT_ALIAS  CG_ALIAS      CC_RUNMODE   CP_DISP_RUN_STATE  CP_NUM_RUN_TASKS  CP_MAX_TASKS  CP_ACTV_MTS_PROCS  CP_MAX_MTS_PROCS  CP_START_TIME        CP_END_TIME          CP_STATUS  CC_INCARN_NO  CC_DESC_TEXT  
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

