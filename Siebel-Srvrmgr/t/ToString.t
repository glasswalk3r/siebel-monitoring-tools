use warnings;
use strict;
use Test::Most tests => 7;
use Siebel::Srvrmgr::ListParser::Output::ListComp::Comp;
use Test::Output 1.03;

my $comp = Siebel::Srvrmgr::ListParser::Output::ListComp::Comp->new(
    {
        alias          => 'FSMSrvr',
        name           => 'File System Manager',
        ct_alias       => 'FSMSrvr',
        cg_alias       => 'SystemAux',
        run_mode       => 'Batch',
        disp_run_state => 'Online',
        start_mode     => 'Auto',
        num_run_tasks  => 0,
        max_tasks      => 20,
        actv_mts_procs => 1,
        max_mts_procs  => 1,
        start_datetime => '2014-01-06 18:22:00',
        status         => 'Enabled',
        incarn_no      => 0,
        time_zone      => 'America/Sao_Paulo',
        desc_text      => 'sample for testing'
    }
);

can_ok( $comp, qw(to_string_header to_string) );
dies_ok { $comp->to_string_header }
'to_string_header expects a separator as parameter';
like( $@, qr/separator must be a single character/,
    'exception is as expected' );
dies_ok { $comp->to_string } 'to_string expects a separator as parameter';
like( $@, qr/separator must be a single character/,
    'exception is as expected' );
my $header =
q{actv_mts_procs#alias#cg_alias#ct_alias#curr_datetime#desc_text#disp_run_state#end_datetime#incarn_no#max_mts_procs#max_tasks#name#num_run_tasks#run_mode#start_datetime#start_mode#status#time_zone};
stdout_is { print $comp->to_string_header('#') } $header,
  'to_string_header prints the expected text';
my $body =
qr#1|FSMSrvr|SystemAux|FSMSrvr|\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}|sample for testing|Online||0|1|20|File System Manager|0|Batch|2014-01-06 18:22:00|Enabled|America/Sao_Paulo#;
stdout_like { print $comp->to_string('|') } $body,
  'to_string prints the expected text';
