package Test::Siebel::Srvrmgr::ListParser::Output::Tabular::ListServers;

use Test::Most;
use parent 'Test::Siebel::Srvrmgr::ListParser::Output::Tabular';

sub get_data_type {

    return 'list_servers';

}

sub get_cmd_line {

    return 'list servers';

}

sub class_methods : Tests(+1) {

    my $test = shift;

    # got from Data::Dumper
    my $parsed_data = {
        'siebel1' => {
            'sblsrvr_state'  => 'Running',
            'sblsrvr_status' => '8.0.0.2 [20412] LANG_INDEPENDENT',
            'start_time'     => '2013-12-08 17:11:25',
            'install_dir' => '/opt/oracle/app/product/8.0.0/siebel_1/siebsrvr',
            'sblmgr_pid'  => '3206',
            'sv_disp_state'      => 'Running',
            'end_time'           => '',
            'sblsrvr_group_name' => '',
            'host_name'          => 'siebel1'
          }
    };

    cmp_deeply(
        $parsed_data,
        $test->get_output()->get_data_parsed(),
        'get_data_parsed() returns the correct data structure'
    );

}

1;
