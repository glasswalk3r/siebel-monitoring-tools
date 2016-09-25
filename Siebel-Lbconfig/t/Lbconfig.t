use warnings;
use strict;
use Test::More;
use Siebel::Lbconfig qw(get_daemon recover_info);
use Siebel::Srvrmgr::Daemon::ActionStash .26;

my $module = 'Siebel::Lbconfig';
can_ok( $module, qw(get_daemon recover_info) );
my $stash = create_fixtures();
note('Testing creating lbconfig data using port 7001 for Siebel Connection Broker');
my $lbconfig_data = recover_info( $stash, 7001 );
is_deeply( $lbconfig_data, exp_lbdata(),
    'recover_info returns the expected data structure' )
  or diag( explain($lbconfig_data) );
done_testing;

sub create_fixtures {

    my $stash = Siebel::Srvrmgr::Daemon::ActionStash->instance;
    $stash->push_stash(
        {
            'EAIObjMgrXXXXX_enu' => [
                'sieb_serv057', 'sieb_serv049',
                'sieb_serv053', 'sieb_serv048',
                'sieb_serv058'
            ],
            'EAIObjMgr_enu' => [
                'sieb_serv045', 'sieb_serv052',
                'sieb_serv057', 'sieb_serv049',
                'sieb_serv053', 'sieb_serv048',
                'sieb_serv058'
            ],
            'SCCObjMgr_enu'      => [ 'sieb_serv053', 'sieb_serv048' ],
            'SCCObjMgr_esn'      => [ 'sieb_serv053', 'sieb_serv048' ],
            'SCCObjMgr_ptb'      => [ 'sieb_serv053', 'sieb_serv048' ],
            'SMObjMgr_enu'       => [ 'sieb_serv056', 'sieb_serv050' ],
            'SMObjMgr_esn'       => [ 'sieb_serv056', 'sieb_serv050' ],
            'SMObjMgr_ptb'       => [ 'sieb_serv056', 'sieb_serv050' ],
            'SMSMLObjMgr_enu'    => [ 'sieb_serv056', 'sieb_serv050' ],
            'SMSMLObjMgr_esn'    => [ 'sieb_serv056', 'sieb_serv050' ],
            'SMSMLObjMgr_ptb'    => [ 'sieb_serv056', 'sieb_serv050' ],
            'SServiceObjMgr_enu' => [ 'sieb_serv053', 'sieb_serv048' ],
            'SServiceObjMgr_esn' => [ 'sieb_serv053', 'sieb_serv048' ],
            'SServiceObjMgr_ptb' => [ 'sieb_serv053', 'sieb_serv048' ],
            'eMarketObjMgr_enu'  => [ 'sieb_serv047', 'sieb_serv046' ],
            'eMarketObjMgr_esn'  => [ 'sieb_serv047', 'sieb_serv046' ],
            'eMarketObjMgr_ptb'  => [ 'sieb_serv047', 'sieb_serv046' ],
            'eServiceObjMgr_enu' => [ 'sieb_serv053', 'sieb_serv048' ],
            'eServiceObjMgr_esn' => [ 'sieb_serv053', 'sieb_serv048' ],
            'eServiceObjMgr_ptb' => [ 'sieb_serv053', 'sieb_serv048' ],
            'loyaltyObjMgr_enu' =>
              [ 'sieb_serv049', 'sieb_serv053', 'sieb_serv048' ],
            'loyaltyObjMgr_enu' => [
                'sieb_serv049', 'sieb_serv053', 'sieb_serv048', 'sieb_serv051'
            ],
            'loyaltyObjMgr_esn' => [
                'sieb_serv049', 'sieb_serv053', 'sieb_serv048', 'sieb_serv051'
            ],
            'loyaltyObjMgr_ptb' => [
                'sieb_serv049', 'sieb_serv053', 'sieb_serv048', 'sieb_serv051'
            ],
            'loyaltySMLObjMgr_enu' =>
              [ 'sieb_serv049', 'sieb_serv053', 'sieb_serv048' ],
            'loyaltySMLObjMgr_esn' =>
              [ 'sieb_serv049', 'sieb_serv053', 'sieb_serv048' ],
            'loyaltySMLObjMgr_ptb' =>
              [ 'sieb_serv049', 'sieb_serv053', 'sieb_serv048' ],
            'loyaltyscwObjMgr_enu' => [ 'sieb_serv047', 'sieb_serv046' ],
            'loyaltyscwObjMgr_esn' => [ 'sieb_serv047', 'sieb_serv046' ],
            'loyaltyscwObjMgr_ptb' => [ 'sieb_serv047', 'sieb_serv046' ]
        }
    );

    $stash->push_stash(
        {
            'sieb_serv045' => 3,
            'sieb_serv046' => 19,
            'sieb_serv047' => 21,
            'sieb_serv048' => 7,
            'sieb_serv049' => 9,
            'sieb_serv050' => 11,
            'sieb_serv051' => 23,
            'sieb_serv052' => 13,
            'sieb_serv053' => 15,
            'sieb_serv056' => 17,
            'sieb_serv057' => 1,
            'sieb_serv058' => 5
        }
    );

    return $stash;

}

sub exp_lbdata {

    return [
'EAIXXXXXENU_VS=1:sieb_serv057:7001;9:sieb_serv049:7001;15:sieb_serv053:7001;7:sieb_serv048:7001;5:sieb_serv058:7001;',
'EAIENU_VS=3:sieb_serv045:7001;13:sieb_serv052:7001;1:sieb_serv057:7001;9:sieb_serv049:7001;15:sieb_serv053:7001;7:sieb_serv048:7001;5:sieb_serv058:7001;',
        'SCCENU_VS=15:sieb_serv053:7001;7:sieb_serv048:7001;',
        'SCCESN_VS=15:sieb_serv053:7001;7:sieb_serv048:7001;',
        'SCCPTB_VS=15:sieb_serv053:7001;7:sieb_serv048:7001;',
        'SMENU_VS=17:sieb_serv056:7001;11:sieb_serv050:7001;',
        'SMESN_VS=17:sieb_serv056:7001;11:sieb_serv050:7001;',
        'SMPTB_VS=17:sieb_serv056:7001;11:sieb_serv050:7001;',
        'SMSMLENU_VS=17:sieb_serv056:7001;11:sieb_serv050:7001;',
        'SMSMLESN_VS=17:sieb_serv056:7001;11:sieb_serv050:7001;',
        'SMSMLPTB_VS=17:sieb_serv056:7001;11:sieb_serv050:7001;',
        'SServiceENU_VS=15:sieb_serv053:7001;7:sieb_serv048:7001;',
        'SServiceESN_VS=15:sieb_serv053:7001;7:sieb_serv048:7001;',
        'SServicePTB_VS=15:sieb_serv053:7001;7:sieb_serv048:7001;',
        'eMarketENU_VS=21:sieb_serv047:7001;19:sieb_serv046:7001;',
        'eMarketESN_VS=21:sieb_serv047:7001;19:sieb_serv046:7001;',
        'eMarketPTB_VS=21:sieb_serv047:7001;19:sieb_serv046:7001;',
        'eServiceENU_VS=15:sieb_serv053:7001;7:sieb_serv048:7001;',
        'eServiceESN_VS=15:sieb_serv053:7001;7:sieb_serv048:7001;',
        'eServicePTB_VS=15:sieb_serv053:7001;7:sieb_serv048:7001;',
'loyaltyENU_VS=9:sieb_serv049:7001;15:sieb_serv053:7001;7:sieb_serv048:7001;23:sieb_serv051:7001;',
'loyaltyESN_VS=9:sieb_serv049:7001;15:sieb_serv053:7001;7:sieb_serv048:7001;23:sieb_serv051:7001;',
'loyaltyPTB_VS=9:sieb_serv049:7001;15:sieb_serv053:7001;7:sieb_serv048:7001;23:sieb_serv051:7001;',
'loyaltySMLENU_VS=9:sieb_serv049:7001;15:sieb_serv053:7001;7:sieb_serv048:7001;',
'loyaltySMLESN_VS=9:sieb_serv049:7001;15:sieb_serv053:7001;7:sieb_serv048:7001;',
'loyaltySMLPTB_VS=9:sieb_serv049:7001;15:sieb_serv053:7001;7:sieb_serv048:7001;',
        'loyaltyscwENU_VS=21:sieb_serv047:7001;19:sieb_serv046:7001;',
        'loyaltyscwESN_VS=21:sieb_serv047:7001;19:sieb_serv046:7001;',
        'loyaltyscwPTB_VS=21:sieb_serv047:7001;19:sieb_serv046:7001;'
    ];

}
