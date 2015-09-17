#!/ood_repository/environment_review/perl5/perls/perl-5.20.1/bin/perl
use warnings;
use strict;
use feature 'say';
use Getopt::Std;
use File::Spec;
use Siebel::Srvrmgr::OS::Unix2;
use DateTime;
use File::HomeDir;
use Readonly;
use RRDs;
use lib '/ood_repository/environment_review';
use Archive;

Readonly my $MY_DBM =>
  File::Spec->catfile( File::HomeDir->my_home(), 'proc_mon.db' );

my %opts;

getopts( 'i:', \%opts );

die "the -i option requires a instance name as value"
  unless ( ( exists( $opts{i} ) ) and ( defined( $opts{i} ) ) );

# /tcfs12/siebel/81/siebsrvr/enterprises/tcfs12/vmsodcfst004/log/tcfs12.vmsodcfst004.log
my $enterprise_log = File::Spec->catfile(
    '',             lc( $opts{i} ),
    'siebel',       '81',
    'siebsrvr',     'enterprises',
    lc( $opts{i} ), $ENV{HOSTNAME},
    'log',          lc( $opts{i} ) . '.' . $ENV{HOSTNAME} . '.log'
);

#/tcfs12/siebel/81
my $siebel_path = File::Spec->catdir( '', lc( $opts{i} ), 'siebel' );

my $procs = Siebel::Srvrmgr::OS::Unix2->new(
    {
        enterprise_log => $enterprise_log,
        use_last_line  => 1,
        cmd_regex      => $siebel_path,

#Se ha creado un proceso servidor con varios subprocesos (pid SO =       3289    ) para XMLPReportServer
        parent_regex =>
'Se\sha\screado\sun\sproceso\sservidor\s(con\svarios\ssubprocesos\s)?',
        archive => Archive->new( { dbm_path => $MY_DBM } )
    }
);

my $now = DateTime->now();
my $timestamp =
    $now->day() . '/'
  . $now->month() . '/'
  . $now->year() . ' '
  . $now->hour() . ':'
  . $now->minute();

my $procs_ref = $procs->get_procs();

# data aggregation by component alias
my %rrd;

my $output = 'output.csv';
open( my $out, '>>', $output ) or die "failed to write to $output: $!";

foreach my $pid ( keys( %{$procs_ref} ) ) {

    print $out join( '|',
        $timestamp,                   $pid,
        $procs_ref->{$pid}->{pctcpu}, $procs_ref->{$pid}->{fname},
        $procs_ref->{$pid}->{pctmem}, $procs_ref->{$pid}->{rss},
        $procs_ref->{$pid}->{vsz},    $procs_ref->{$pid}->{comp_alias} ),
      "\n";
      
    if (exists($rrd{$procs_ref->{$pid}->{comp_alias}})) {
    
        $rrd{$procs_ref->{$pid}->{comp_alias}}->[0] += $procs_ref->{$pid}->{pctcpu};
        $rrd{$procs_ref->{$pid}->{comp_alias}}->[1] += $procs_ref->{$pid}->{pctmem};
    
    } else {
    
        $rrd{$procs_ref->{$pid}->{comp_alias}} = [];
    
        $rrd{$procs_ref->{$pid}->{comp_alias}}->[0] = $procs_ref->{$pid}->{pctcpu};
        $rrd{$procs_ref->{$pid}->{comp_alias}}->[1] = $procs_ref->{$pid}->{pctmem};
    
    }
    
}

close($out);
%{$procs_ref} = ();
$procs_ref = undef;

# must avoid trying to update DSN that were not created if components are changed without warning
my @avail_comps = (qw(AdminNotify ApptBook AsgnSrvr CommConfigMgr CommInboundProcessor CommInboundRcvr CommOutboundMgr CommSessionMgr EAIObjMgr_esn eCommunicationsObjMgr_esn eProdCfgObjMgr_esn FSCyccnt FSFulfill FSInvTxn FSLocate FSMSrvr FSPrevMnt FSRepl Optimizer SCBroker SCCObjMgr_esn ServerMgr SRBroker SRProc SvrTaskPersist WfProcBatchMgr WfProcMgr WfRecvMgr XMLPReportServer));

my (@dsns, @cpu, @mem);

foreach my $comp_alias( @avail_comps ) {

    my $temp_alias = substr($comp_alias,0,19); # due restrictions of RRDTool
    push(@dsns, $temp_alias);
    push(@cpu, $rrd{$comp_alias}->[0]);
    push(@mem, $rrd{$comp_alias}->[1]);

}


my $filename = 'siebel_server_cpu.rrd';
RRDs::update( $filename, '--template', (join(':',@dsns)), (join(':', $now->epoch, @cpu )) );
my $ERR=RRDs::error;
die "ERROR while updating $filename: $ERR\n" if $ERR;
$filename = 'siebel_server_mem.rrd';
RRDs::update( $filename, '--template', (join(':',@dsns)), (join(':', $now->epoch, @mem )) );
$ERR=RRDs::error;
die "ERROR while updating mydemo.rrd: $ERR\n" if $ERR;
