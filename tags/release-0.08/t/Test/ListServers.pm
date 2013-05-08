package Test::ListServers;

use Test::Most;
use Test::Moose qw(has_attribute_ok);
use base 'Test::Class';

sub class { 'Siebel::Srvrmgr::ListParser::Output::ListServers' }

sub startup : Tests(startup => 1) {

    my $test = shift;
    use_ok $test->class;
}

sub constructor : Tests(5) {

    my $test  = shift;
    my $class = $test->class;

    can_ok( $class, 'new' );

    my @data = <Test::ListServers::DATA>;
    close(Test::ListServers::DATA);

    ok(
        my $servers = $class->new(
            {
                data_type => 'list_servers',
                raw_data  => \@data,
                cmd_line  => 'list servers'
            }
        ),
        '... and the constructor should succeed'
    );

    has_attribute_ok( $servers, 'attribs' );

    isa_ok( $servers, $class, '... and the object it returns' );

    # got from Data::Dumper
    my $parsed_data = {
        'siebelsrv03' => {
            'sblsrvr_state'      => 'Running',
            'sblsrvr_status'     => '8.1.1.7 [21238] LANG_INDEPENDENT',
            'start_time'         => '2012-11-14 00:11:36',
            'install_dir'        => '/app/siebel/siebsrvr',
            'sblmgr_pid'         => '28483',
            'sv_disp_state'      => 'Running',
            'end_time'           => '',
            'sblsrvr_group_name' => '',
            'host_name'          => 'siebelsrv03'
        },
        'siebelsrv01' => {
            'sblsrvr_state'      => 'Running',
            'sblsrvr_status'     => '8.1.1.7 [21238] LANG_INDEPENDENT',
            'start_time'         => '2012-11-14 00:11:00',
            'install_dir'        => '/app/siebel/siebsrvr',
            'sblmgr_pid'         => '17188',
            'sv_disp_state'      => 'Running',
            'end_time'           => '',
            'sblsrvr_group_name' => '',
            'host_name'          => 'siebelsrv01'
        },
        'siebelsrv04' => {
            'sblsrvr_state'      => 'Running',
            'sblsrvr_status'     => '8.1.1.7 [21238] LANG_INDEPENDENT',
            'start_time'         => '2012-11-14 00:11:29',
            'install_dir'        => '/app/siebel/siebsrvr',
            'sblmgr_pid'         => '25371',
            'sv_disp_state'      => 'Running',
            'end_time'           => '',
            'sblsrvr_group_name' => '',
            'host_name'          => 'siebelsrv04'
        },
        'siebelsrv02' => {
            'sblsrvr_state'      => 'Running',
            'sblsrvr_status'     => '8.1.1.7 [21238] LANG_INDEPENDENT',
            'start_time'         => '2012-11-14 00:11:19',
            'install_dir'        => '/app/siebel/siebsrvr',
            'sblmgr_pid'         => '19812',
            'sv_disp_state'      => 'Running',
            'end_time'           => '',
            'sblsrvr_group_name' => '',
            'host_name'          => 'siebelsrv02'
        }
    };

    cmp_deeply(
        $parsed_data,
        $servers->get_data_parsed(),
        'get_data_parsed() returns the correct data structure'
    );

}

1;

__DATA__
SBLSRVR_NAME  SBLSRVR_GROUP_NAME  HOST_NAME    INSTALL_DIR           SBLMGR_PID  SV_DISP_STATE  SBLSRVR_STATE  START_TIME           END_TIME  SBLSRVR_STATUS                    
------------  ------------------  -----------  --------------------  ----------  -------------  -------------  -------------------  --------  --------------------------------  
siebelsrv01                       siebelsrv01  /app/siebel/siebsrvr  17188       Running        Running        2012-11-14 00:11:00            8.1.1.7 [21238] LANG_INDEPENDENT  
siebelsrv02                       siebelsrv02  /app/siebel/siebsrvr  19812       Running        Running        2012-11-14 00:11:19            8.1.1.7 [21238] LANG_INDEPENDENT  
siebelsrv03                       siebelsrv03  /app/siebel/siebsrvr  28483       Running        Running        2012-11-14 00:11:36            8.1.1.7 [21238] LANG_INDEPENDENT  
siebelsrv04                       siebelsrv04  /app/siebel/siebsrvr  25371       Running        Running        2012-11-14 00:11:29            8.1.1.7 [21238] LANG_INDEPENDENT  

4 rows returned.

