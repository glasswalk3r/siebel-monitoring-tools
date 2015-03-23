use warnings;
use strict;
use Test::More tests => 1;
use Siebel::Srvrmgr::ListParser::Output::ListComp::Comp;
use DateTime;

my $start = DateTime->now();
my $end   = $start->clone;

my $elapsed  = $start->minute + 10;
my $interval = 0;

 # :WORKAROUND:23-03-2015 03:03:37:: cannot set minute > 59
if ( $elapsed > 59 ) {

    $interval = $elapsed * 60;
    $end->set_minute($elapsed);

}

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

is( $comp->get_duration, $interval, "component executed for $elapsed minutes" );
