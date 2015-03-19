use warnings;
use strict;
use Test::More tests => 1;
use Siebel::Srvrmgr::ListParser::Output::ListComp::Comp;
use DateTime;

my $start = DateTime->now();
my $end   = $start->clone;
$end->set_minute( $start->minute + 10 );

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

is($comp->get_duration, 600, 'component executed for 10 minutes');
