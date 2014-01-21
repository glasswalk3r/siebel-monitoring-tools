use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok('Siebel::Srvrmgr::Nagios') }

$SIG{INT} = \&clean_up;

my $config = create_config();
my @args = ( 'perl', 'comp_mon.pl', '-w', '1', '-c', '3', '-f', $config );
system(@args);

is( ( $? >> 8 ), 2, 'comp_mon.pl returns a CRITICAL' )
  or diag( check_exec($?) );

sub clean_up {

    unlink($config) or die "Could not remove $config: $!";

}

sub check_exec {

    my $error_code = shift;

    if ( $error_code == -1 ) {
        return "failed to execute: $!\n";
    }
    elsif ( $error_code & 127 ) {
        return sprintf(
            "child died with signal %d, %s coredump",
            (
                ( $error_code & 127 ),
                ( $error_code & 128 ) ? 'with' : 'without'
            )
        );
    }
    else {

        return sprintf "child exited with value %d\n", $? >> 8;

    }

}

sub create_config {

    my $cfg = 'test.xml';

    open( my $out, '>:utf8', $cfg ) or die "Cannot create $cfg: $!";

    print $out <<BLOCK;
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<ns1:siebelMonitor xmlns:ns1="http://code.google.com/p/siebel-monitoring-tools/">
	<ns1:connection>
		<ns1:siebelServer>siebfoobar</ns1:siebelServer>
		<ns1:srvrmgrPath>$Config{sitebin}</ns1:srvrmgrPath>
BLOCK

    while (<DATA>) {

        print $out $_;

    }

    close(DATA);
    close($out);
    return $cfg;

}

__DATA__
		<ns1:srvrmgrExec>srvrmgr-mock.pl</ns1:srvrmgrExec>
		<ns1:siebelEnterprise>foobar</ns1:siebelEnterprise>
		<ns1:siebelGateway>siebelgw</ns1:siebelGateway>
		<ns1:user>sadmin</ns1:user>
		<ns1:password>sadmin</ns1:password>
	</ns1:connection>
	<ns1:servers>
		<ns1:server name="siebfoobar">
			<ns1:components>
				<ns1:component alias="EAIObjMgr_ptb" description="EAI Object Manager (PTB)" ComponentGroup="EAI" OKStatus="Shutdown" criticality="1"/>
				<ns1:component alias="eChannelCMEObjMgr_enu" description="eChannel Power Communications Object Manager (ENU)" ComponentGroup="Communications" OKStatus="Shutdown" criticality="1"/>
				<ns1:component alias="eChannelCMEObjMgr_ptb" description="eChannel Power Communications Object Manager (PTB)" ComponentGroup="Communications" OKStatus="Shutdown" criticality="1"/>
				<ns1:component alias="eCommunicationsObjMgr_enu" description="eCommunications Object Manager (ENU)" ComponentGroup="Communications" OKStatus="Shutdown" criticality="1"/>
				<ns1:component alias="ADMBatchProc" description="Application Deployment Manager Batch Processor" ComponentGroup="ADM" criticality="1"/>
				<ns1:component alias="ADMObjMgr_enu" description="Application Deployment Manager Object Manager (ENU)" ComponentGroup="ADM" criticality="1"/>
				<ns1:component alias="ADMObjMgr_ptb" description="Application Deployment Manager Object Manager (PTB)" ComponentGroup="ADM" criticality="1"/>
				<ns1:component alias="ADMProc" description="Application Deployment Manager Processor" ComponentGroup="ADM" criticality="1"/>
				<ns1:component alias="BusIntBatchMgr" description="Business Integration Batch Manager" ComponentGroup="EAI" criticality="1"/>
				<ns1:component alias="BusIntMgr" description="Business Integration Manager" ComponentGroup="EAI" criticality="1"/>
				<ns1:component alias="EAIObjMgr_enu" description="EAI Object Manager (ENU)" ComponentGroup="EAI" criticality="4"/>
				<ns1:component alias="EIM" description="Enterprise Integration Mgr" ComponentGroup="EAI" criticality="2"/>
				<ns1:component alias="FSMSrvr" description="File System Manager" ComponentGroup="SystemAux" criticality="4"/>
				<ns1:component alias="GenTrig" description="Generate Triggers" ComponentGroup="Workflow" criticality="1"/>
				<ns1:component alias="JMSReceiver" description="JMS Receiver" ComponentGroup="EAI" criticality="4"/>
				<ns1:component alias="ListImportSvcMgr" description="List Import Service Manager" ComponentGroup="MktgSrv" criticality="2"/>
				<ns1:component alias="ServerMgr" description="Server Manager" ComponentGroup="System" criticality="4"/>
				<ns1:component alias="SRBroker" description="Server Request Broker" ComponentGroup="System" criticality="4"/>
				<ns1:component alias="SRProc" description="Server Request Processor" ComponentGroup="SystemAux" criticality="4"/>
				<ns1:component alias="SvrTblCleanup" description="Server Tables Cleanup" ComponentGroup="SystemAux" criticality="4"/>
				<ns1:component alias="SvrTaskPersist" description="Server Task Persistance" ComponentGroup="SystemAux" criticality="4"/>
				<ns1:component alias="AdminNotify" description="Siebel Administrator Notification Component" ComponentGroup="SystemAux" criticality="1"/>
				<ns1:component alias="SCBroker" description="Siebel Connection Broker" ComponentGroup="System" criticality="4"/>
				<ns1:component alias="TaskLogCleanup" description="Task Log Cleanup" ComponentGroup="TaskUI" criticality="4"/>
				<ns1:component alias="WorkActn" description="Workflow Action Agent" ComponentGroup="Workflow" criticality="2"/>
				<ns1:component alias="WorkMon" description="Workflow Monitor Agent" ComponentGroup="Workflow" criticality="2"/>
				<ns1:component alias="WorkMonSWI" description="Workflow Monitor Agent SWI" ComponentGroup="Workflow" criticality="2"/>
				<ns1:component alias="WfProcBatchMgr" description="Workflow Process Batch Manager" ComponentGroup="Workflow" criticality="4"/>
				<ns1:component alias="WfProcMgr" description="Workflow Process Manager" ComponentGroup="Workflow" criticality="4"/>
				<ns1:component alias="WfRecvMgr" description="Workflow Recovery Manager" ComponentGroup="Workflow" criticality="4"/>
				<ns1:component alias="eCommunicationsObjMgr_ptb" description="eCommunications Object Manager (PTB)" ComponentGroup="Communications" criticality="4"/>
			</ns1:components>
			<ns1:componentsGroups>
				<ns1:componentGroup name="ADM" defaultOKStatus="Online|Running"/>
				<ns1:componentGroup name="EAI" defaultOKStatus="Online|Running"/>
				<ns1:componentGroup name="Workflow" defaultOKStatus="Online|Running"/>
				<ns1:componentGroup name="MktgSrv" defaultOKStatus="Online|Running"/>
				<ns1:componentGroup name="System" defaultOKStatus="Online|Running"/>
				<ns1:componentGroup name="SystemAux" defaultOKStatus="Online|Running"/>
				<ns1:componentGroup name="TaskUI" defaultOKStatus="Online|Running"/>
				<ns1:componentGroup name="Communications" defaultOKStatus="Online|Running"/>
			</ns1:componentsGroups>
		</ns1:server>
	</ns1:servers>
</ns1:siebelMonitor>
