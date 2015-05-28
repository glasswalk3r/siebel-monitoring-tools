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
            'SBLSRVR_STATE'  => 'Running',
            'SBLSRVR_STATUS' => '8.0.0.2 [20412] LANG_INDEPENDENT',
            'START_TIME'     => '2013-12-08 17:11:25',
            'INSTALL_DIR' => '/opt/oracle/app/product/8.0.0/siebel_1/siebsrvr',
            'SBLMGR_PID'  => '3206',
            'SV_DISP_STATE'      => 'Running',
            'END_TIME'           => '',
            'SBLSRVR_GROUP_NAME' => '',
            'HOST_NAME'          => 'siebel1'
          }
    };

    cmp_deeply(
        $parsed_data,
        $test->get_output()->get_data_parsed(),
        'get_data_parsed() returns the correct data structure'
    );

}

1;
