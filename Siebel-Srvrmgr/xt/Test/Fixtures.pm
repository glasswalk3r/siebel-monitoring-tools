package Test::Fixtures;
use Exporter 'import';
use lib 't';

our @EXPORT_OK = qw(build_server);

# __DATA__ must be kept in tandem with srvrmgr-mock output for "list comp" command
# each line must be in the format CP_ALIAS|CP_DISP_RUN_STATE
sub build_server {
    my ( $server_name, $comp_list ) = @_;
    my @comps;

    if ( defined($comp_list) ) {
        my @list = split( /\|/, $comp_list );

        foreach (@list) {
            push(
                @comps,
                Test::Siebel::Srvrmgr::Daemon::Action::Check::Component->new(
                    {
                        alias          => $_,
                        description    => 'whatever',
                        componentGroup => 'whatever',
                        OKStatus       => 'Running|Online',
                        taskOKStatus   => 'Running|Online',
                        criticality    => 5
                    }
                )
            );
        }
    }
    else {

        while (<DATA>) {
            chomp();
            my ( $comp_alias, $status ) = ( split( /\|/, $_ ) );
            push(
                @comps,
                Test::Siebel::Srvrmgr::Daemon::Action::Check::Component->new(
                    {
                        alias          => $comp_alias,
                        description    => 'whatever',
                        componentGroup => 'whatever',
                        OKStatus       => $status,
                        taskOKStatus   => 'Running|Online',
                        criticality    => 5
                    }
                )
            );
        }
        close(DATA);

    }

    return Test::Siebel::Srvrmgr::Daemon::Action::Check::Server->new(
        {
            name       => $server_name,
            components => \@comps
        }
    );

}

__DATA__
AsgnSrvr|Online
AsgnBatch|Online
CommConfigMgr|Online
CommInboundProcessor|Online
CommInboundRcvr|Online
CommOutboundMgr|Online
CommSessionMgr|Online
EAIObjMgr_enu|Online
EAIObjMgrXXXXX_enu|Online
InfraEAIOutbound|Online
MailMgr|Online
EIM|Online
FSMSrvr|Online
JMSReceiver|Shutdown
MqSeriesAMIRcvr|Shutdown
MqSeriesSrvRcvr|Shutdown
MSMQRcvr|Shutdown
PageMgr|Shutdown
SMQReceiver|Shutdown
ServerMgr|Running
SRBroker|Running
SRProc|Running
SvrTblCleanup|Shutdown
SvrTaskPersist|Running
AdminNotify|Online
SCBroker|Running
SmartAnswer|Shutdown
LoyEngineBatch|Shutdown
LoyEngineInteractive|Shutdown
LoyEngineRealtime|Online
LoyEngineRealtimeTier|Online
