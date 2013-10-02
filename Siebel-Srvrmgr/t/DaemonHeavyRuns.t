use warnings;
use strict;
use Test::Most;
use Siebel::Srvrmgr::Daemon::Heavy;
use Siebel::Srvrmgr::Daemon::Action::CheckComps;
use Siebel::Srvrmgr::Daemon::ActionStash;
use Cwd;
use File::Spec;
use lib 't';
use Test::Siebel::Srvrmgr::Daemon::Action::CheckComps::Component;
use Test::Siebel::Srvrmgr::Daemon::Action::CheckComps::Server;

my $server = build_server();
my $repeat = 3;

plan tests => ( scalar( @{ $server->components() } ) + 2 ) * $repeat;

my $daemon = Siebel::Srvrmgr::Daemon::Heavy->new(
    {
        gateway     => 'whatever',
        enterprise  => 'whatever',
        user        => 'whatever',
        password    => 'whatever',
        server      => 'whatever',
        bin         => File::Spec->catfile( getcwd(), 'srvrmgr-mock.pl' ),
        use_perl    => 1,
        is_infinite => 0,
        timeout     => 0,
        commands    => [
            Siebel::Srvrmgr::Daemon::Command->new(
                command => 'list comp',
                action  => 'CheckComps',
                params  => [$server]
            )
        ]
    }
);

my $stash = Siebel::Srvrmgr::Daemon::ActionStash->instance();

for ( 1 .. $repeat ) {

    $daemon->run();

    my $data = $stash->shift_stash();

    is( scalar( keys( %{$data} ) ), 1, 'only one server is returned' );

    my ($servername) = keys( %{$data} );
    is( $servername, $server->name(), 'returned server name is correct' );

  SKIP: {

        skip 'Cannot test component status if server is not defined',
          scalar( @{ $server->components() } )
          unless ( defined($servername) );

        foreach my $comp ( keys( %{ $data->{$servername} } ) ) {

            ok( $data->{$servername}->{$comp}, "component $comp status is ok" );

        }

    }

}

sub build_server {

    my @comps;

    while (<DATA>) {

        chomp();

        push(
            @comps,
            Test::Siebel::Srvrmgr::Daemon::Action::CheckComps::Component->new(
                {
                    name           => $_,
                    description    => 'whatever',
                    componentGroup => 'whatever',
                    OKStatus       => 'Running|Online',
                    criticality    => 5
                }
            )
        );

    }
    close(DATA);

    return Test::Siebel::Srvrmgr::Daemon::Action::CheckComps::Server->new(
        {
            name       => 'siebfoobar',
            components => \@comps
        }
    );

}

__DATA__
ADMBatchProc
ADMObjMgr_enu
ADMObjMgr_ptb
ADMProc
AsgnSrvr
AsgnBatch
BusIntBatchMgr
BusIntMgr
CommConfigMgr
CommInboundProcessor
CommInboundRcvr
CommOutboundMgr
CommSessionMgr
CustomAppObjMgr_enu
CustomAppObjMgr_ptb
DbXtract
EAIObjMgr_enu
EAIObjMgr_ptb
MailMgr
EIM
FSMSrvr
GenNewDb
GenTrig
htimObjMgr_enu
htimObjMgr_ptb
htimprmObjMgr_enu
htimprmObjMgr_ptb
JMSReceiver
ListImportSvcMgr
PDbXtract
RepAgent
FooAssetRecCMon
FooAssetWorkMon
ServerMgr
SRBroker
SRProc
SvrTblCleanup
SvrTaskPersist
AdminNotify
SCBroker
SynchMgr
TaskLogCleanup
WorkActn
WorkMon
WorkMonSWI
WfProcBatchMgr
WfProcMgr
WfRecvMgr
eChannelCMEObjMgr_enu
eChannelCMEObjMgr_ptb
eCommunicationsObjMgr_enu
eCommunicationsObjMgr_ptb

