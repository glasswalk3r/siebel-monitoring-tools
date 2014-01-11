package Test::Siebel::Srvrmgr::ListParser::Output::ListComp::Comp;

use Test::Most;
use Test::Moose 'has_attribute_ok';
use parent 'Test::Siebel::Srvrmgr';
use Siebel::Srvrmgr::ListParser::Output::Tabular::ListComp;

sub get_struct {

    my $test = shift;

    return $test->{structure_type};

}

sub get_col_sep {

    my $test = shift;

    return $test->{col_sep};

}

# :TODO:11-01-2014:: should refactor this because behaviour is the same for other classes (maybe a Role?)
# overriding parent's because the files will have the command itself followed by the output of it
sub get_my_data {

    my $test = shift;

    my $data_ref = $test->SUPER::get_my_data();

    shift( @{$data_ref} );    #command
    shift( @{$data_ref} );    #new line

    return $data_ref;

}

sub _constructor : Tests(2) {

    my $test = shift;

    my $list_comp;

    if ( ( $test->get_struct eq 'delimited' ) and ( $test->get_col_sep ) ) {

        $list_comp =
          Siebel::Srvrmgr::ListParser::Output::Tabular::ListComp->new(
            {
                data_type      => 'list_comp',
                raw_data       => $test->get_my_data(),
                cmd_line       => 'list comp',
                structure_type => $test->get_struct(),
                col_sep        => $test->get_col_sep()
            }
          );

    }
    else {

        $list_comp =
          Siebel::Srvrmgr::ListParser::Output::Tabular::ListComp->new(
            {
                data_type      => 'list_comp',
                raw_data       => $test->get_my_data(),
                cmd_line       => 'list comp',
                structure_type => $test->get_struct()
            }
          );

    }

    my $server = $list_comp->get_server('siebel1');

    my $alias = 'SRProc';

    ok(
        $test->{comp} = $test->class()->new(
            { data => $server->get_data()->{$alias}, cc_alias => $alias }
        ),
        'the constructor should succeed'
    );

    isa_ok( $test->{comp}, $test->class(),
        'the object is a instance of the correct class' );

}

sub class_attributes : Tests(17) {

    my $test = shift;

    my @attribs = (
        'data',              'cc_alias',
        'cc_name',           'ct_alias',
        'ct_name',           'cg_alias',
        'cc_runmode',        'cp_disp_run_state',
        'cp_num_run_tasks',  'cp_max_tasks',
        'cp_actv_mts_procs', 'cp_max_mts_procs',
        'cp_start_time',     'cp_end_time',
        'cp_status',         'cc_incarn_no',
        'cc_desc_text'
    );

    foreach my $attrib (@attribs) {

        has_attribute_ok( $test->{comp}, $attrib );

    }
}

sub class_methods : Tests(15) {

    my $test = shift;

    can_ok( $test->{comp},
        qw(get_data cc_alias cc_name ct_alias ct_name cg_alias cc_runmode cp_disp_run_state cp_num_run_tasks cp_max_tasks cp_actv_mts_procs cp_max_mts_procs cp_start_time cp_end_time cp_status cc_incarn_no cc_desc_text)
    );

    is( $test->{comp}->cp_num_run_tasks(),
        2, 'cp_num_run_tasks returns the correct value' );
    is( $test->{comp}->cc_incarn_no(),
        0, 'cc_incarn_no returns the correct value' );
    is(
        $test->{comp}->cc_name(),
        'Server Request Processor',
        'ccn_name returns the correct value'
    );
    is( $test->{comp}->ct_alias(),
        'SRProc', 'ct_alias returns the correct value' );
    is( $test->{comp}->cg_alias(),
        'SystemAux', 'cg_alias returns the correct value' );
    is( $test->{comp}->cc_runmode(),
        'Interactive', 'cc_runmode returns the correct value' );
    is( $test->{comp}->cp_disp_run_state(),
        'Running', 'cp_disp_run_state returns the correct value' );
    is( $test->{comp}->cp_max_tasks(),
        20, 'cp_max_tasks returns the correct value' );
    is( $test->{comp}->cp_actv_mts_procs(),
        1, 'cp_actv_mts_procs returns the correct value' );
    is( $test->{comp}->cp_max_mts_procs(),
        1, 'cp_max_mts_procs returns the correct value' );
    is(
        $test->{comp}->cp_start_time(),
        '2014-01-06 18:22:00',
        'cp_start_time returns the correct value'
    );
    is( $test->{comp}->cp_end_time(),
        '', 'cp_end_time returns the correct value' );
    is( $test->{comp}->cp_status(),
        'Enabled', 'cp_status returns the correct value' );
    is( $test->{comp}->cc_desc_text(),
        '', 'cc_desc_text returns the correct value' );

}

1;

