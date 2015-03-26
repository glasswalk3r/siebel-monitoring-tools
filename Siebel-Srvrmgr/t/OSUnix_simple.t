use warnings;
use strict;
use Test::More;
use Test::Moose qw(has_attribute_ok);
use Cwd;

eval "use Siebel::Srvrmgr::OS::Unix";
plan skip_all => "Siebel::Srvrmgr::OS::Unix is required for running these tests" if $@;
my $cwd            = getcwd();
my $enterprise_log = $cwd . '/foobar.foobar666.log';

# :WORKAROUND:22-03-2015 19:58:18:: setting to this hardcode because the hack to define $0 for a running process
# set both fname and cmndline attributes of Proc::ProcessTable::Process
my $proc_name = 'siebmtshmw';
my @attribs =
  (
    qw(enterprise_log parent_regex cmd_regex mem_limit cpu_limit limits_callback)
  );

my @methods = (
    'get_ent_log',      'set_ent_log',
    'get_parent_regex', 'set_parent_regex',
    'get_cmd',          'set_cmd',
    'get_mem_limit',    'set_mem_limit',
    '_find_pid',        'get_procs'
);

plan tests => scalar(@attribs) + 9;

SKIP: {

# :REMARK:23-03-2015 02:23:56:: perl 5.8.9 does not allow the change of fname in /proc by changing $0
    eval q{use Proc::Background};

    skip "Cannot run this test because of \"$@\"", 8, if $@;

    my $proc_path = "$cwd/$proc_name";

    open( my $script, '>', $proc_path ) or die "Cannot create $$proc_path: $!";

my $code = q{#!/usr/bin/perl
#let's put child to do something
while (1) {

    my $a = 0;
    my $b = 1;
    my $n = 2000;

    for ( 0 .. ( $n - 1 ) ) {
        my $sum = $a + $b;
        $a = $b;
        $b = $sum;
    }

    sleep 1;

}};

    print $script $code;
    close($script);
	chmod 0700, $proc_path;
    my $siebel_proc = Proc::Background->new( $proc_path );

    # giving some time to get data into /proc
    sleep 3;

    create_ent_log( $siebel_proc->pid, $enterprise_log );
    my $procs = Siebel::Srvrmgr::OS::Unix->new(
        {
            enterprise_log => $enterprise_log,
            cmd_regex      => $cwd, 
            parent_regex =>
'Created\s(multithreaded\s)?server\sprocess\s\(OS\spid\s\=\s+\d+\s+\)\sfor\s\w+'
        }
    );

    my $procs_ref = $procs->get_procs;
    is( ref($procs_ref), 'HASH', 'get_procs returns a hash reference' );
    is( scalar( keys( %{$procs_ref} ) ),
        1, 'get_procs returns a single process' );
    my $pid = ( keys( %{$procs_ref} ) )[0];
    is( $procs_ref->{$pid}->{comp_alias},
        'EAIObjMgr_enu', 'process has the correct component alias associated' );
    is( $procs_ref->{$pid}->{fname},
        'siebmtshmw', 'process has the correct process name' );

    my $float   = qr/\d+(\.\d+)?/;
    my $integer = qr/\d+/;

    like( $procs_ref->{$pid}->{pctcpu}, $float, 'process %CPU is a float' );
    like( $procs_ref->{$pid}->{pctmem}, $float, 'process %memory is a float' );
    like( $procs_ref->{$pid}->{rss}, $integer, 'process RSS is a integer' );
    like( $procs_ref->{$pid}->{vsz}, $integer, 'process VSZ is a integer' );

    $siebel_proc->die;

    unlink $enterprise_log or warn "Failed to remove $enterprise_log: $!";
    unlink $proc_path      or warn "Failed to remove $proc_path: $!";

}

basic_tests();

###################################################
# SUBS

sub basic_tests {

    my $procs = Siebel::Srvrmgr::OS::Unix->new(
        {
            enterprise_log => $enterprise_log,
            cmd_regex      => "^$proc_name",

            #Created multithreaded server process (OS pid = 	9644	) for SRProc
            parent_regex =>
'Created\s(multithreaded\s)?server\sprocess\s\(OS\spid\s\=\s+\d+\s+\)\sfor\s\w+_\w+'
        }
    );

    can_ok( $procs, @methods );

    foreach my $attrib (@attribs) {

        has_attribute_ok( $procs, $attrib );

    }

}

sub create_ent_log {

    my $grand_child_pid = shift;
    my $log_file        = shift;
    my @lines           = <DATA>;
    close(DATA);

    $lines[48] =~ s/GRAND_CHILD_PID/$grand_child_pid/;

    open( my $out, '>', $log_file ) or die "Cannot create $log_file=: $!";
    foreach my $line (@lines) {

        chomp($line);
        print $out $line, "\015\012";

    }

    close($out);

}

__DATA__
2021 2015-03-05 13:15:40 0000-00-00 00:00:00 -0600 00000000 001 003f 0001 09 SiebSrvr 0 9589 -151398720 /foobar/siebel/81/siebsrvr/enterprises/foobar/foobar666/log/foobar.foobar666.log 8.1.1.11 [23030] ENU
ServerLog	ServerStartup	1	025fd5e954de5141:0	2015-03-05 13:15:40	Siebel Enterprise Applications Server is starting up

ServerLog	LstnObjCreate	1	0260131054de5141:0	2015-03-05 13:15:41	Created port 49156 for EAI Outbound Server
ServerLog	LstnObjCreate	1	0260133454de5141:0	2015-03-05 13:15:41	Created port 49157 for JMS Receiver
ServerLog	LstnObjCreate	1	0260133454de5141:0	2015-03-05 13:15:41	Created port 33526 for File System Manager
ServerLog	LstnObjCreate	1	0260133454de5141:0	2015-03-05 13:15:41	Created port 49158 for Server Request Processor
ServerLog	LstnObjCreate	1	0260133454de5141:0	2015-03-05 13:15:41	Created port 49159 for Siebel Administrator Notification Component
ServerLog	LstnObjCreate	1	0260133454de5141:0	2015-03-05 13:15:41	Created port 49160 for eLoyalty Processing Engine - Realtime - Tier
ServerLog	LstnObjCreate	1	0260133454de5141:0	2015-03-05 13:15:41	Created port 49161 for eLoyalty Processing Engine - Realtime
ServerLog	LstnObjCreate	1	0260133454de5141:0	2015-03-05 13:15:41	Created port 49162 for eLoyalty Processing Engine - Interactive
ServerLog	LstnObjCreate	1	0260133454de5141:0	2015-03-05 13:15:41	Created port 49163 for eLoyalty Processing Engine - Batch
ServerLog	LstnObjCreate	1	0260133454de5141:0	2015-03-05 13:15:41	Created port 33562 for Server Request Broker
ServerLog	LstnObjCreate	1	0260133454de5141:0	2015-03-05 13:15:41	Created port 33563 for Server Manager
ServerLog	LstnObjCreate	1	0260133454de5141:0	2015-03-05 13:15:41	Created port 33530 for Siebel Connection Broker
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	SRBroker	STARTING	Component is starting up.
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	SRBroker	INITIALIZED	Component has initialized (no spawned procs).
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	ServerMgr	STARTING	Component is starting up.
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	ServerMgr	INITIALIZED	Component has initialized (no spawned procs).
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	SiebSrvr	STARTING	Component is starting up.
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	SiebSrvr	INITIALIZED	Component has initialized (no spawned procs).
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	SCBroker	STARTING	Component is starting up.
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	SrvrSched	STARTING	Component is starting up.
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	SrvrSched	INITIALIZED	Component has initialized (no spawned procs).
ServerLog	ProcessCreate	1	0000149754f82575:0	2015-03-05 13:15:41	Created multithreaded server process (OS pid = 	9632	) for SRBroker
ServerLog	ProcessCreate	1	0000149754f82575:0	2015-03-05 13:15:41	Created server process (OS pid = 	9633	) for SCBroker
ServerLog	ProcessCreate	1	0000149754f82575:0	2015-03-05 13:15:41	Created server process (OS pid = 	9641	) for SCBroker
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	SCBroker	INITIALIZED	Component has initialized.
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	SRProc	STARTING	Component is starting up.
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	SRProc	INITIALIZED	Component has initialized (no spawned procs).
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	FSMSrvr	STARTING	Component is starting up.
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	FSMSrvr	INITIALIZED	Component has initialized (no spawned procs).
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	AdminNotify	STARTING	Component is starting up.
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	AdminNotify	INITIALIZED	Component has initialized (no spawned procs).
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	SvrTaskPersist	STARTING	Component is starting up.
ServerLog	ProcessCreate	1	0000149754f82575:0	2015-03-05 13:15:41	Created multithreaded server process (OS pid = 	9644	) for SRProc
ServerLog	ProcessCreate	1	0000149754f82575:0	2015-03-05 13:15:41	Created multithreaded server process (OS pid = 	9645	) for FSMSrvr
ServerLog	ProcessCreate	1	0000149754f82575:0	2015-03-05 13:15:41	Created multithreaded server process (OS pid = 	9651	) for AdminNotify
ServerLog	ProcessCreate	1	0000149754f82575:0	2015-03-05 13:15:41	Created server process (OS pid = 	9677	) for SvrTaskPersist
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:51	SvrTaskPersist	INITIALIZED	Component has initialized.
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:51	EAIObjMgr_enu	STARTING	Component is starting up.
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:51	EAIObjMgr_enu	INITIALIZED	Component has initialized (no spawned procs).
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:51	LoyEngineRealtimeTier	STARTING	Component is starting up.
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:51	LoyEngineRealtimeTier	INITIALIZED	Component has initialized (no spawned procs).
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:51	LoyEngineBatch	STARTING	Component is starting up.
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:51	LoyEngineBatch	INITIALIZED	Component has initialized (no spawned procs).
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:51	LoyEngineInteractive	STARTING	Component is starting up.
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:51	LoyEngineInteractive	INITIALIZED	Component has initialized (no spawned procs).
ServerLog	ProcessCreate	1	0000149754f82575:0	2015-03-05 13:15:51	Created server process (OS pid = 	GRAND_CHILD_PID	) for EAIObjMgr_enu
ServerLog	ServerStarted	1	0261889854de5141:0	2015-03-05 13:15:51	Siebel Application Server is ready and awaiting requests
