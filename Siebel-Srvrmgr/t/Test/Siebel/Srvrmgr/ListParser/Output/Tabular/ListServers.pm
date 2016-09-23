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
        'sieb_serv057' => {
            'SBLSRVR_STATE'      => 'Running',
            'SBLSRVR_STATUS'     => '8.1.1.11 [23030] LANG_INDEPENDENT',
            'START_TIME'         => '2016-09-22 14:17:33',
            'INSTALL_DIR'        => '/foobar/siebel/81/siebsrvr',
            'SBLMGR_PID'         => '1431',
            'SV_DISP_STATE'      => 'Running',
            'END_TIME'           => '',
            'SBLSRVR_GROUP_NAME' => '',
            'HOST_NAME'          => 'sieb_serv057',
            'SV_SRVRID'          => '1'
        }
    };

    cmp_deeply(
        $parsed_data,
        $test->get_output()->get_data_parsed(),
        'get_data_parsed() returns the correct data structure'
    );
}

1;
