#!/usr/bin/perl
use warnings;
use strict;
use feature qw(switch);

our $VERSION = 0.01;

$SIG{INT} = sub { die "\nDisconnecting...\n" };

put_text( hello() );

while (1) {

    put_text('srvrmgr> ');

    chomp( my $command = <STDIN> );

    given ($command) {

        when (/^list\scomp\stype/) {
            list_comp_types();
        }

        when (/^list\scomp\sdef/) {

            put_text( list_comp_def() );

        }

        when (/^list\scomp/) {
            put_text( list_comp() );
        }

        when ('load preferences') {

            put_text(
"File: C:\\Siebel\\8.0\\web client\\BIN\\.Siebel_svrmgr.pref\n\n"
            );

        }

        when ('exit') {
            put_text("\nDisconnecting...\n");
            last;
        }

        when ('') {

            put_text("\n");

        }

        default { put_text("Invalid command\n") }

    }
}

exit 0;

sub put_text {

    my $text = shift;

    syswrite( STDOUT, $text );

}

sub list_comp_def {

    return <<BLOCK;

CC_NAME                                                                       CT_NAME                                                                       CC_RUNMODE                       CC_ALIAS                         CC_DISP_ENABLE_ST                                              CC_DESC_TEXT                                                                                                                                                                                                                                                 CG_NAME                                                                       CG_ALIAS                         CC_INCARN_NO             
----------------------------------------------------------------------------  ----------------------------------------------------------------------------  -------------------------------  -------------------------------  -------------------------------------------------------------  --------------------------------------------------------------------------------------------------------------------  ----------------------------------------------------------------------------  -------------------------------  -----------------------  
Server Request Processor                                                      Server Request Processor (SRP)                                                Interactive                      SRProc                           Active                                                         Server Request scheduler and request/notification store and forward processor                                                                                                                                                                                Auxiliary System Management                                                   SystemAux                        0                        

1 row returned.

BLOCK

}

sub hello {

    return <<BLOCK;
Siebel Enterprise Applications Siebel Server Manager, Version 8.0.0.7 [20426] LANG_INDEPENDENT
Ahn... well, not exactly.
This is Server Manager Simulator, Version $VERSION [20426] LANG_INDEPENDENT 
Copyright (c) 2012 Siebel Monitoring Tools. Released under GPL version 3.
See http://code.google.com/p/siebel-gnu-tools/ for more details.

Type "help" for list of commands, "help <topic>" for detailed help

Connected to 1 server(s) out of a total of 1 server(s) in the enterprise

BLOCK

}

sub list_comp_types {

    while (<DATA>) {

        syswrite( STDOUT, $_ );

    }

    close(DATA);

}

sub list_comp {

    return <<BLOCK;

SV_NAME     CC_ALIAS              CC_NAME                               CT_ALIAS  CG_ALIAS      CC_RUNMODE   CP_DISP_RUN_STATE  CP_NUM_RUN_TASKS  CP_MAX_TASKS  CP_ACTV_MTS_PROCS  CP_MAX_MTS_PROCS  CP_START_TIME        CP_END_TIME          CP_STATUS  CC_INCARN_NO  CC_DESC_TEXT  
----------  --------------------  ------------------------------------  --------  ------------  -----------  -----------------  ----------------  ------------  -----------------  ----------------  -------------------  -------------------  ---------  ------------  ------------  
foobar1234  WorkMonitorFoobar     Foobar Confirm Date Alert                       Workflow      Background   Active             0                 1                                                  2012-02-18 17:14:35                                                              
foobar1234  ClientAdmin           Client Administration                           System        Background   Active             0                 1                                                  2012-02-18 17:14:35                                                              
foobar1234  DbXtract              Database Extract                                Remote        Batch        Active             0                 50                                                 2012-02-18 17:14:35                                                              
foobar1234  MailMgr               Email Manager                                   CommMgmt      Background   Active             0                 20                                                 2012-02-18 17:14:35                                                              
foobar1234  FSMSrvr               File System Manager                             System        Batch        Active             0                 20            1                  1                 2012-02-18 17:14:35                                                              
foobar1234  GenNewDb              Generate New Database                           Remote        Batch        Active             0                 1                                                  2012-02-18 17:14:35                                                              
foobar1234  GenTrig               Generate Triggers                               Workflow      Batch        Active             0                 1                                                  2012-02-18 17:14:35                                                              
foobar1234  PageMgr               Page Manager                                    CommMgmt      Background   Active             0                 20                                                 2012-02-18 17:14:35                                                              
foobar1234  PDbXtract             Parallel Database Extract                       Remote        Batch        Executing          4                 10            1                  1                 2012-02-18 17:14:35                                                              
foobar1234  ServerMgr             Server Manager                                  System        Interactive  Executing          1                 20                                                 2012-02-18 17:14:35                                                              
foobar1234  SRBroker              Server Request Broker                           System        Interactive  Executing          6                 100           1                  1                 2012-02-18 17:14:35                                                              
foobar1234  SRProc                Server Request Processor                        System        Interactive  Executing          2                 20            1                  1                 2012-02-18 17:14:35                                                              
foobar1234  SynchMgr              Synchronization Manager                         Remote        Interactive  Active             0                 100           1                  20                2012-02-18 20:46:30                                                              
foobar1234  TxnMerge              Transaction Merger                              Remote        Background   Executing          1                 5                                                  2012-02-18 17:14:35                                                              
foobar1234  TxnProc               Transaction Processor                           Remote        Background   Executing          1                 1                                                  2012-02-18 17:14:35                                                              
foobar1234  TxnRoute              Transaction Router                              Remote        Background   Executing          3                 5                                                  2012-02-18 17:14:35                                                              
foobar1234  UpgKitBldr            Upgrade Kit Builder                             SiebAnywhere  Batch        Active             0                 1             1                  1                 2012-02-18 17:14:35                                                              
foobar1234  ePharmaObjMgr_ptb     ePharma Object Manager (PTB)                    LifeSciences  Interactive  Fechar             0                 60            0                  2                                      2012-02-18 17:14:35                                         
foobar1234  ePharmaObjMgr_COM_pt  ePharma Object Manager COM (PTB)                LifeSciences  Interactive  Executing          6                 60            1                  2                 2012-02-18 17:14:35                                                              

19 rows returned.

BLOCK

}

__DATA__

CT_NAME                                                                       CT_RUNMODE                       CT_ALIAS                                                       CT_DESC_TEXT
----------------------------------------------------------------------------  -------------------------------  -------------------------------------------------------------  --------------------------------------------------------------------------------------------------------------------
Request Test Server                                                           Batch                            TestReq                                                        Component used for testing Request Mode Server
Test SCF Facilities                                                           Batch                            TestScfFacilities                                              Component used for testing new SCF facilities.
Test SCF Facilities                                                           Background                       TestScfFacilities                                              Component used for testing new SCF facilities.
Session Test Server                                                           Interactive                      TestSess                                                       Component used for testing Session Mode Server
Test Server                                                                   Batch                            TestSrvr                                                       Component used for testing Client Administration
Test Server                                                                   Background                       TestSrvr                                                       Component used for testing Client Administration
Transaction Merger                                                            Background                       TxnMerge                                                       Merges transactions from Siebel Remote clients
Transaction Processor                                                         Background                       TxnProc                                                        Prepares the transaction log for the Transaction Router
Transaction Router                                                            Background                       TxnRoute                                                       Routes visible transactions to Siebel Remote clients
UDA Service                                                                   Batch                            UDA Service                                                    UDA Service Service
UDA Service                                                                   Background                       UDA Service                                                    UDA Service Service
Universal Data Cleansing Service                                              Batch                            Universal Data Cleansing Service                               Universal Data Cleansing Service Service
Universal Data Cleansing Service                                              Background                       Universal Data Cleansing Service                               Universal Data Cleansing Service Service
UoM Conversion Business Service                                               Batch                            UoM Conversion Business Service                                UoM Conversion Business Service Service
UoM Conversion Business Service                                               Background                       UoM Conversion Business Service                                UoM Conversion Business Service Service
Update Manager                                                                Batch                            UpdateMgr                                                      Server component that will update DNB and List Management
Upgrade Kit Wizard OMSV                                                       Batch                            Upgrade Kit Wizard OMSV                                        Upgrade Kit Wizard OMSV Service
Upgrade Kit Wizard OMSV                                                       Background                       Upgrade Kit Wizard OMSV                                        Upgrade Kit Wizard OMSV Service
Workflow Action Agent                                                         Background                       WorkActn                                                       Executes actions for pre-defined events
Workflow Monitor Agent                                                        Background                       WorkMon                                                        Monitors the database for pre-defined events
Workflow Process Manager                                                      Batch                            Workflow Process Manager                                       Workflow Process Manager Service
Workflow Process Manager                                                      Background                       Workflow Process Manager                                       Workflow Process Manager Service
Workflow Recovery Manager                                                     Batch                            Workflow Recovery Manager                                      Workflow Recovery Manager Service
Workflow Recovery Manager                                                     Background                       Workflow Recovery Manager                                      Workflow Recovery Manager Service
eAuto VDS Accessorization Utility Service                                     Batch                            eAuto VDS Accessorization Utility Service                      eAuto VDS Accessorization Utility Service Service
eAuto VDS Accessorization Utility Service                                     Background                       eAuto VDS Accessorization Utility Service                      eAuto VDS Accessorization Utility Service Service

26 rows returned.

