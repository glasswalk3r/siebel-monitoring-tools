use warnings;
use strict;
use Test::More tests => 1;
use Siebel::Srvrmgr::ListParser::Output::ListComp::Comp;
use DateTime;

$ENV{SIEBEL_TZ} = 'America/Sao_Paulo';

my $start = DateTime->now();
note( 'Now is ' . $start );
my $end           = $start->clone;
my $interval      = 10;
my $interval_secs = $interval * 60;
note("Considering that component finished after $interval minutes");
$end->add( minutes => $interval );
note( 'End time will be ' . $end );

my $comp = Siebel::Srvrmgr::ListParser::Output::ListComp::Comp->new(
    {
        alias          => 'SRProc',
        name           => 'Server Request Processor',
        ct_alias       => 'SRProc',
        cg_alias       => 'SystemAux',
        run_mode       => 'Interactive',
        disp_run_state => 'Running',
        num_run_tasks  => 2,
        max_tasks      => 20,
        actv_mts_procs => 1,
        max_mts_procs  => 1,
        start_datetime => $start->strftime('%F %H:%M:%S'),
        end_datetime   => $end->strftime('%F %H:%M:%S'),
        status         => 'Enabled',
        incarn_no      => 0,
        desc_text      => ''

    }

);

is( $comp->get_duration, $interval_secs,
    "component executed for $interval_secs seconds" );

delete $ENV{SIEBEL_TZ};
