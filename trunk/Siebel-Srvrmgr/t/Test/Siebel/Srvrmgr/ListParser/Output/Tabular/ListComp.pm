package Test::Siebel::Srvrmgr::ListParser::Output::Tabular::ListComp;

use Test::Most;
use Test::Moose 'has_attribute_ok';
use Hash::Util qw(lock_keys unlock_keys);
use base 'Test::Siebel::Srvrmgr::ListParser::Output::Tabular';

sub class_attributes : Tests(no_plan) {

    my $test = shift;

    $test->SUPER::class_attributes( [qw(last_server comp_attribs servers)] );

}

sub get_structure_type {

    my $test = shift;

    return $test->{structure_type};

}

sub get_col_sep {

    my $test = shift;
    return $test->{col_sep};

}

sub get_output_file {

    my $test = shift;

    return $test->{output_file};

}

#overriding Test::Siebel::Srvrmgr get_my_data to be able to read text files
sub get_my_data {

    my $test = shift;

    open( my $in, '<', $test->get_output_file() )
      or die 'cannot read ' . $test->get_output_file() . ': ' . $!;

    my @data = <$in>;
    close($in);

    $test->{data} = \@data;
    return $test->{data};

}

sub _constructor : Test(no_plan) {

    my $test = shift;

    if ( $test->get_col_sep() ) {

        $test->SUPER::_constructor(
            {
                last_server    => 'siebel1',
                structure_type => $test->get_structure_type(),
                col_sep        => $test->get_col_sep()
            }
        );

    }
    else {

        # this server name is expected from the files used for testing
        $test->SUPER::_constructor(
            {
                last_server    => 'siebel1',
                structure_type => $test->get_structure_type()
            }
        );

    }

}

sub get_last_server {

    return 'siebel1';

}

sub get_servers {

    my $test = shift;
    return [ $test->get_last_server() ];

}

sub class_methods : Tests(+5) {

    my $test = shift;

    $test->SUPER::class_methods(
        qw(get_fields_pattern get_comp_attribs get_last_server get_servers get_server)
    );

    my $comp_attribs = [
        qw(CC_NAME CT_ALIAS CG_ALIAS CC_RUNMODE CP_DISP_RUN_STATE CP_NUM_RUN_TASKS CP_MAX_TASKS CP_ACTV_MTS_PROCS CP_MAX_MTS_PROCS CP_START_TIME CP_END_TIME CP_STATUS CC_INCARN_NO CC_DESC_TEXT)
    ];

    is_deeply( $test->get_output()->get_comp_attribs(),
        $comp_attribs,
        'get_fields_pattern returns a correct set of attributes' );

    is(
        $test->get_output()->get_last_server(),
        $test->get_last_server(),
        'get_last_server returns the correct server name'
    );

    is_deeply( $test->get_output()->get_servers(),
        $test->get_servers(),
        'get_servers returns the correct array reference' );

    my $server_class = 'Siebel::Srvrmgr::ListParser::Output::ListComp::Server';

    my $server;

    ok(
        $server =
          $test->get_output()
          ->get_server( $test->get_output()->get_last_server() ),
        'get_server returns an object'
    );

  SKIP: {

        skip 'get_server() method failed', 1 unless ( defined($server) );

        isa_ok( $server, $server_class );

    }

}

1;
