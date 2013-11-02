use warnings;
use strict;
use Test::Most;
use Siebel::Srvrmgr::Daemon::Heavy;
use Siebel::Srvrmgr::Daemon::Action::CheckComps;
use Siebel::Srvrmgr::Daemon::ActionStash;
use Cwd;
use File::Spec;
use Config::Tiny;
use lib 't';
use Test::Siebel::Srvrmgr::Daemon::Action::CheckComps::Component;
use Test::Siebel::Srvrmgr::Daemon::Action::CheckComps::Server;

my $daemon;
my $server;

if ( $ENV{SIEBEL_SRVRMGR_DEVEL} and ( -e $ENV{SIEBEL_SRVRMGR_DEVEL} ) ) {

    my $cfg = Config::Tiny->read( $ENV{SIEBEL_SRVRMGR_DEVEL} );
    $server = build_server( $cfg->{_}->{server}, $cfg->{_}->{comp_list} );

    $daemon = Siebel::Srvrmgr::Daemon::Heavy->new(
        {
            gateway    => $cfg->{_}->{gateway},
            enterprise => $cfg->{_}->{enterprise},
            user       => $cfg->{_}->{user},
            password   => $cfg->{_}->{password},
            server     => $cfg->{_}->{server},
            bin        => File::Spec->catfile(
                $cfg->{_}->{srvrmgr_path},
                $cfg->{_}->{srvrmgr_bin}
            ),
            use_perl     => 0,
            is_infinite  => 0,
            read_timeout => 15,
            commands     => [
                Siebel::Srvrmgr::Daemon::Command->new(
                    command => 'load preferences',
                    action  => 'LoadPreferences',
                    params  => [$server]
                ),
                Siebel::Srvrmgr::Daemon::Command->new(
                    command => 'list comp',
                    action  => 'CheckComps',
                    params  => [$server]
                )
            ]
        }
    );

}
else {

    $server = build_server('siebfoobar');

    $daemon = Siebel::Srvrmgr::Daemon::Heavy->new(
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

}

my $repeat      = 12;
my $total_tests = ( scalar( @{ $server->components() } ) + 2 ) * $repeat;
plan tests => $total_tests;
set_log();
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

sub set_log {

    my $log_file = File::Spec->catfile( getcwd(), 'daemon.log' );
    my $log_cfg  = File::Spec->catfile( getcwd(), 'log4perl.cfg' );

    my $config = <<BLOCK;
log4perl.logger.Siebel.Srvrmgr.Daemon = WARN, LOG1
log4perl.appender.LOG1 = Log::Log4perl::Appender::File
log4perl.appender.LOG1.filename  = $log_file
log4perl.appender.LOG1.mode = clobber
log4perl.appender.LOG1.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.LOG1.layout.ConversionPattern = %d %p> %F{1}:%L %M - %m%n
BLOCK

    open( my $out, '>', $log_cfg )
      or die 'Cannot create ' . $log_cfg . ": $!\n";
    print $out $config;
    close($out) or die 'Could not close ' . $log_cfg . ": $!\n";

    $ENV{SIEBEL_SRVRMGR_DEBUG} = $log_cfg;

}

sub build_server {

    my $server_name = shift;
    my $comp_list   = shift;
    my @comps;

    if ( defined($comp_list) ) {

        my @list = split( /\|/, $comp_list );

        foreach (@list) {

            push(
                @comps,
                Test::Siebel::Srvrmgr::Daemon::Action::CheckComps::Component
                  ->new(
                    {
                        alias          => $_,
                        description    => 'whatever',
                        componentGroup => 'whatever',
                        OKStatus       => 'Running|Online',
                        criticality    => 5
                    }
                  )
            );

        }

    }
    else {

        while (<DATA>) {

            chomp();

            push(
                @comps,
                Test::Siebel::Srvrmgr::Daemon::Action::CheckComps::Component
                  ->new(
                    {
                        alias          => $_,
                        description    => 'whatever',
                        componentGroup => 'whatever',
                        OKStatus       => 'Running|Online',
                        criticality    => 5
                    }
                  )
            );

        }
        close(DATA);

    }

    return Test::Siebel::Srvrmgr::Daemon::Action::CheckComps::Server->new(
        {
            name       => $server_name,
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
