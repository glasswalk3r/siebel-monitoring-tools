package Test::ListParams;

use Test::Most;
use base 'Test::Class';

sub class { 'Siebel::Srvrmgr::ListParser::Output::ListParams' }

sub startup : Tests(startup => 1) {

    my $test = shift;
    use_ok $test->class;
}

sub constructor : Tests(8) {

    my $test  = shift;
    my $class = $test->class;

    can_ok( $class, 'new' );

    #extended method tests
    can_ok( $class,
        qw(parse get_params set_params get_server get_comp_alias _set_details)
    );

    my @data = <Test::ListParams::DATA>;
    close(Test::ListParams::DATA);

    ok(
        my $params = $class->new(
            {
                data_type => 'list_params',
                raw_data  => \@data,
                cmd_line  => 'list params for server foo component bar'
            }
        ),
        '... and the constructor should succeed'
    );

    isa_ok( $params, $class, '... and the object it returns' );

    is( $params->get_fields_pattern(),
        'A22A32A13A11A29A23A23A46', 'fields_patterns is correct' );

    my $default_params = [
        qw(PA_ALIAS PA_VALUE PA_DATATYPE PA_SCOPE PA_SUBSYSTEM PA_SETLEVEL PA_DISP_SETLEVEL PA_NAME)
    ];

    is_deeply( $params->get_params(), $default_params,
        'get_fields_pattern returns a correct set of attributes' );

    my $server = 'foo';
    is( $params->get_server(), $server, "get_server returns $server" );

    my $comp_alias = 'bar';
    is( $params->get_comp_alias(),
        $comp_alias, "get_comp_alias returns $comp_alias" );

}

1;

__DATA__
PA_ALIAS              PA_VALUE                        PA_DATATYPE  PA_SCOPE   PA_SUBSYSTEM                 PA_SETLEVEL            PA_DISP_SETLEVEL       PA_NAME                                       
--------------------  ------------------------------  -----------  ---------  ---------------------------  ---------------------  ---------------------  --------------------------------------------  
16KTblSpace                                           String       Subsystem  Database Access              SIS_NEVER_SET          SIS_NEVER_SET          16K Tablespace Name                           
32KTblSpace                                           String       Subsystem  Database Access              SIS_NEVER_SET          SIS_NEVER_SET          32K Tablespace Name                           
ActionAgent           False                           Boolean      Component                               SIS_DEFAULT_SET        SIS_DEFAULT_SET        Use Action Agent                              
ActionInterval        3600                            Integer      Component                               SIS_DEFAULT_SET        SIS_DEFAULT_SET        Action interval                               
AutoRestart           False                           Boolean      Subsystem  Process Management           SIS_DEFAULT_SET        SIS_DEFAULT_SET        Auto Restart                                  
BatchMode             False                           Boolean      Component                               SIS_DEFAULT_SET        SIS_DEFAULT_SET        Process the batch Policies                    
CACertFileName                                        String       Subsystem  Networking                   SIS_NEVER_SET          SIS_NEVER_SET          CA certificate file name                      
CertFileName                                          String       Subsystem  Networking                   SIS_NEVER_SET          SIS_NEVER_SET          Certificate file name                         
CheckLogCacheSz       100                             Integer      Component                               SIS_DEFAULT_SET        SIS_DEFAULT_SET        Cache size of Policy violations               
CommType              TCPIP                           String       Subsystem  Networking                   SIS_DEFAULT_SET        SIS_DEFAULT_SET        Communication Transport                       
CompVIP                                               String       Subsystem  Networking                   SIS_NEVER_SET          SIS_NEVER_SET          Component Virtual IP Address                  
Compress              NONE                            String       Subsystem  Networking                   SIS_DEFAULT_SET        SIS_DEFAULT_SET        Compression Type                              
ConnIdleTime          -1                              Integer      Subsystem  Networking                   SIS_DEFAULT_SET        SIS_DEFAULT_SET        SISNAPI connection maximum idle time          
Connect               SiebSrvr_DEV                    String       Subsystem  Database Access                                                            ODBC Data Source                              
Crypt                 None                            String       Subsystem  Networking                                                                 Encryption Type                               
DB2DisableAutoCommit  Y                               String       Subsystem  Database Access              SIS_DEFAULT_SET        SIS_DEFAULT_SET        Disable Autocommit                            
DB2DisableMinMemMode                                  String       Subsystem  Database Access              SIS_NEVER_SET          SIS_NEVER_SET          Disable DB2 CLI MinMemMode                    
DBRollbackSeg                                         String       Subsystem  Database Access              SIS_NEVER_SET          SIS_NEVER_SET          DataBase Rollback Segment Name                
DeleteSize            500                             Integer      Component                               SIS_DEFAULT_SET        SIS_DEFAULT_SET        Request delete size                           
DfltTasks             1                               Integer      Subsystem  Process Management           SIS_COMPDEF_LEVEL_SET  SIS_COMPDEF_LEVEL_SET  Default Tasks                                 
ErrorFlags            0                               Integer      Subsystem  Event Logging                SIS_DEFAULT_SET        SIS_DEFAULT_SET        Error Flags                                   
FileSystem            \\foobar\fs                     String       Subsystem  Infrastructure Core                                                        Siebel File System                            
GenReqRetry           120                             Integer      Component                               SIS_DEFAULT_SET        SIS_DEFAULT_SET        Number of seconds to retry                    
GroupName             Foobar Policy Group             String       Component                               SIS_COMPDEF_LEVEL_SET  SIS_COMPDEF_LEVEL_SET  Group Name                                    
HTTPKeepAlive         0                               Integer      Subsystem  Networking                   SIS_DEFAULT_SET        SIS_DEFAULT_SET        Server http keepalive time                    
IdxSpace                                              String       Subsystem  Database Access              SIS_NEVER_SET          SIS_NEVER_SET          Indexspace Name                               
IgnoreError           False                           Boolean      Component                               SIS_DEFAULT_SET        SIS_DEFAULT_SET        Ignore errors                                 
KeepLogDays           30                              Integer      Component                               SIS_DEFAULT_SET        SIS_DEFAULT_SET        Number of days to keep violation information  
KeyFileName                                           String       Subsystem  Networking                   SIS_NEVER_SET          SIS_NEVER_SET          Private key file name                         
KeyFilePassword       ********                        String       Subsystem  Networking                   SIS_NEVER_SET          SIS_NEVER_SET          Private key file password                     
Lang                  PTB                             String       Subsystem  Infrastructure Core                                                        Language Code                                 
LastUsrCacheSz        100                             Integer      Component                               SIS_DEFAULT_SET        SIS_DEFAULT_SET        Cache size of last user information           
LogArchive            10                              Integer      Subsystem  Event Logging                SIS_DEFAULT_SET        SIS_DEFAULT_SET        Log Archive Keep                              
LogTimestamp          False                           Boolean      Subsystem  Event Logging                SIS_DEFAULT_SET        SIS_DEFAULT_SET        Log Print Timestamp                           
LogUseSharedFile      False                           Boolean      Subsystem  Event Logging                SIS_DEFAULT_SET        SIS_DEFAULT_SET        Use Shared Log File                           
LongTblSpace                                          String       Subsystem  Database Access              SIS_NEVER_SET          SIS_NEVER_SET          Long Tablespace Name                          
MailServer                                            String       Component                               SIS_NEVER_SET          SIS_NEVER_SET          Mail Server                                   
MailTo                                                String       Component                               SIS_NEVER_SET          SIS_NEVER_SET          Mailing Address                               
MaxTasks              5                               Integer      Subsystem  Process Management           SIS_COMPDEF_LEVEL_SET  SIS_COMPDEF_LEVEL_SET  Maximum Tasks                                 
MinUpTime             60                              Integer      Subsystem  Process Management           SIS_DEFAULT_SET        SIS_DEFAULT_SET        Minimum Up Time                               
NumRestart            10                              Integer      Subsystem  Process Management           SIS_DEFAULT_SET        SIS_DEFAULT_SET        Numbers of Restarts                           
NumRetries            10000                           Integer      Subsystem  Recovery                     SIS_DEFAULT_SET        SIS_DEFAULT_SET        Number of Retries                             
Password              ********                        String       Subsystem  Database Access                                                            Password                                      
PeerAuth              False                           Boolean      Subsystem  Networking                   SIS_DEFAULT_SET        SIS_DEFAULT_SET        Peer Authentication                           
PeerCertValidation    False                           Boolean      Subsystem  Networking                   SIS_DEFAULT_SET        SIS_DEFAULT_SET        Validate peer certificate                     
PortNumber            0                               Integer      Subsystem  Networking                   SIS_DEFAULT_SET        SIS_DEFAULT_SET        Static Port Number                            
ReloadPolicy          86400                           Integer      Component                               SIS_DEFAULT_SET        SIS_DEFAULT_SET        Reload Policy                                 
Repository            Siebel Repository               String       Subsystem  Database Access              SIS_DEFAULT_SET        SIS_DEFAULT_SET        Siebel Repository                             
Requests              5000                            Integer      Component                               SIS_DEFAULT_SET        SIS_DEFAULT_SET        Requests per iteration                        
RetryInterval         5                               Integer      Subsystem  Recovery                     SIS_DEFAULT_SET        SIS_DEFAULT_SET        Retry Interval                                
RetryUpTime           600                             Integer      Subsystem  Recovery                     SIS_DEFAULT_SET        SIS_DEFAULT_SET        Retry Up Time                                 
SARMEnabled           False                           Boolean      Subsystem  (SARM) Response Measurement  SIS_DEFAULT_SET        SIS_DEFAULT_SET        SARM Enabled                                  
SARMMaxFileSize       15000000                        Integer      Subsystem  (SARM) Response Measurement  SIS_DEFAULT_SET        SIS_DEFAULT_SET        SARM Data File Size Limit                     
SARMMaxMemory         4000000                         Integer      Subsystem  (SARM) Response Measurement  SIS_DEFAULT_SET        SIS_DEFAULT_SET        SARM Memory Size Limit                        
SQLFlags              0                               Integer      Subsystem  Event Logging                SIS_DEFAULT_SET        SIS_DEFAULT_SET        SQL Trace Flags                               
SQLTraceThreshold                                     String       Subsystem  Database Access              SIS_NEVER_SET          SIS_NEVER_SET          SQL Trace Threshold                           
SRB ReqId             0                               String       Subsystem  Infrastructure Core          SIS_DEFAULT_SET        SIS_DEFAULT_SET        SRB RequestId                                 
SleepTime             60                              Integer      Subsystem  Infrastructure Core          SIS_DEFAULT_SET        SIS_DEFAULT_SET        Sleep Time                                    
TableGroupFile                                        String       Subsystem  Database Access              SIS_NEVER_SET          SIS_NEVER_SET          Table Groupings File                          
TableOwnPass          ********                        String       Subsystem  Database Access              SIS_NEVER_SET          SIS_NEVER_SET          Table Owner Password                          
TableOwner            SIEBEL                          String       Subsystem  Database Access                                                            Table Owner                                   
TblSpace                                              String       Subsystem  Database Access              SIS_NEVER_SET          SIS_NEVER_SET          Tablespace Name                               
TraceFlags            0                               Integer      Subsystem  Event Logging                SIS_DEFAULT_SET        SIS_DEFAULT_SET        Trace Flags                                   
Username              SADMIN                          String       Subsystem  Database Access                                                            User Name                                     

64 rows returned.

