package Test::Siebel::Srvrmgr::Daemon::Action::Dumper;

use base qw(Test::Siebel::Srvrmgr::Daemon::Action);
use Test::More;

sub class_methods : Test(+1) {

    my $test = shift;

# :WORKAROUND:03-06-2013:arfreitas: redirecting STDOUT to avoid having problems with TAP
    close(STDOUT);

	# redirecting parent class execution
    my $test_data;
    open( STDOUT, '>', \$test_data )
      or die "Failed to redirect STDOUT to in-memory file: $!";
    $test->SUPER::class_methods();
    close(STDOUT);

    $test_data = undef;
    open( STDOUT, '>', \$test_data )
      or die "Failed to redirect STDOUT to in-memory file: $!";
    $test->{action}->do( $test->get_my_data() );
    close(STDOUT);

    like(
        $test_data,
        qr/Siebel::Srvrmgr::ListParser::Output::ListParams/,
        'Dumper output matches expected regular expression'
    );

}

1;

__DATA__
srvrmgr> list params for component SRProc

PA_ALIAS                 PA_VALUE           PA_DATATYPE  PA_SCOPE   PA_SUBSYSTEM                 PA_SETLEVEL       PA_DISP_SETLEVEL                PA  PA  PA  PA  PA_NAME                                         
-----------------------  -----------------  -----------  ---------  ---------------------------  ----------------  ------------------------------  --  --  --  --  ----------------------------------------------  
CACertFileName                              String       Subsystem  Networking                   Never set         Never set                       N   N   Y   N   CA certificate file name                        
CertFileName                                String       Subsystem  Networking                   Never set         Never set                       N   N   Y   N   Certificate file name                           
ConnIdleTime             -1                 Integer      Subsystem  Networking                   Default value     Default value                   Y   N   N   N   SISNAPI connection maximum idle time            
Connect                  Siebel_DSN         String       Subsystem  Database Access              Enterprise level  Enterprise level set            Y   N   N   N   ODBC Data Source                                
DisableNotification      False              Boolean      Subsystem  Infrastructure Notification  Default value     Default value                   N   N   N   N   Disable Notification                            
EnableDbSessCorrelation  False              Boolean      Subsystem  Database Access              Default value     Default value                   Y   N   N   N   Enable Database Session Correlation             
EnableHousekeeping       False              Boolean      Component                               Default value     Default value                   N   N   N   N   Enable Various Housekeeping Tasks               
EnableUsageTracking      False              Boolean      Subsystem  Usage Tracking               Default value     Default value                   N   N   N   N   UsageTracking Enabled                           
FDRAppendFile            False              Boolean      Subsystem  (FDR) Flight Data Recorder   Default value     Default value                   N   N   N   N   FDR Periodic Dump and Append                    
FDRBufferSize            5000000            Integer      Subsystem  (FDR) Flight Data Recorder   Default value     Default value                   N   Y   N   Y   FDR Buffer Size                                 
KeyFileName                                 String       Subsystem  Networking                   Never set         Never set                       N   N   Y   N   Private key file name                           
KeyFilePassword          ********           String       Subsystem  Networking                   Never set         Never set                       N   N   Y   N   Private key file password                       
Lang                     enu                String       Subsystem  Infrastructure Core          Server level      Server level set                Y   N   N   N   Language Code                                   
LogArchiveDir                               String       Subsystem  Event Logging                Never set         Never set                       Y   N   N   N   Log Archive Directory                           
LogDir                                      String       Subsystem  Event Logging                Never set         Never set                       N   N   N   N   Log directory                                   
LogFileDir               c:\temp            String       Subsystem  Usage Tracking               Default value     Default value                   N   N   N   N   UsageTracking LogFile Dir                       
LogFileEncoding          ASCII              String       Subsystem  Usage Tracking               Default value     Default value                   N   N   N   N   UsageTracking LogFile Encoding                  
LogFileFormat            XML                String       Subsystem  Usage Tracking               Default value     Default value                   N   N   N   N   UsageTracking LogFile Format                    
LogFilePeriod            Hourly             String       Subsystem  Usage Tracking               Default value     Default value                   N   N   N   N   UsageTracking LogFile Period                    
LogMaxSegments           100                Integer      Subsystem  Event Logging                Compdef level     Component definition level set  N   N   N   N   Maximum number of log file segments             
LogSegmentSize           100                Integer      Subsystem  Event Logging                Compdef level     Component definition level set  N   N   N   N   Log file segment size in KB                     
MaxMTServers             1                  Integer      Subsystem  Multi-Threading              Compdef level     Component definition level set  N   N   Y   N   Maximum MT Servers                              
MaxTasks                 20                 Integer      Subsystem  Process Management           Compdef level     Component definition level set  N   N   Y   N   Maximum Tasks                                   
MemoryBasedRecycle       False              Boolean      Subsystem  Multi-Threading              Default value     Default value                   Y   N   N   N   Memory usage based multithread shell recycling  
MemoryLimit              1500               Integer      Subsystem  Multi-Threading              Default value     Default value                   Y   N   N   N   Process VM usage lower limit                    
MemoryLimitPercent       20                 Integer      Subsystem  Multi-Threading              Default value     Default value                   Y   N   N   N   Process VM usage upper limit                    
MinMTServers             1                  Integer      Subsystem  Multi-Threading              Compdef level     Component definition level set  N   N   Y   N   Minimum MT Servers                              
NotifyHandler            AdminEmailAlert    String       Subsystem  Infrastructure Notification  Server level      Server level set                N   N   N   N   Notification Handler                            
NotifyTimeOut            100                Integer      Subsystem  Infrastructure Notification  Default value     Default value                   N   N   N   N   Time to wait for doing notification             
NumRetries               10000              Integer      Subsystem  Recovery                     Default value     Default value                   Y   N   N   N   Number of Retries                               
Password                 ********           String       Subsystem  Database Access              Enterprise level  Enterprise level set            Y   N   N   N   Password                                        
PeerAuth                 False              Boolean      Subsystem  Networking                   Default value     Default value                   N   N   Y   N   Peer Authentication                             
PeerCertValidation       False              Boolean      Subsystem  Networking                   Default value     Default value                   N   N   Y   N   Validate peer certificate                       
Repository               Siebel Repository  String       Subsystem  Database Access              Default value     Default value                   Y   N   N   N   Siebel Repository                               
RetryInterval            5                  Integer      Subsystem  Recovery                     Default value     Default value                   Y   N   N   N   Retry Interval                                  
RetryUpTime              600                Integer      Subsystem  Recovery                     Default value     Default value                   Y   N   N   N   Retry Up Time                                   
SARMLevel                0                  Integer      Subsystem  (SARM) Response Measurement  Default value     Default value                   N   N   N   N   SARM Granularity Level                          
SRB ReqId                0                  String       Subsystem  Infrastructure Core          Default value     Default value                   Y   N   N   N   SRB RequestId                                   
SessionCacheSize         100                Integer      Subsystem  Usage Tracking               Default value     Default value                   N   N   N   N   UsageTracking Session Cache Size                
TableOwnPass             ********           String       Subsystem  Database Access              Never set         Never set                       Y   N   N   N   Table Owner Password                            
TableOwner               SIEBEL             String       Subsystem  Database Access              Enterprise level  Enterprise level set            Y   N   N   N   Table Owner                                     
TblSpace                                    String       Subsystem  Database Access              Never set         Never set                       Y   N   N   N   Tablespace Name                                 
UserList                                    String       Subsystem  Event Logging                Never set         Never set                       N   N   N   N   List of users                                   
Username                 SADMIN             String       Subsystem  Database Access              Enterprise level  Enterprise level set            Y   N   N   N   User Name                                       

44 rows returned.

