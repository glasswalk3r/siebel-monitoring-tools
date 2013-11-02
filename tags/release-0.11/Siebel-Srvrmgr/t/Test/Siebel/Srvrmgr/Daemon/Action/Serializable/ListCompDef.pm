package Test::Siebel::Srvrmgr::Daemon::Action::Serializable::ListCompDef;

use base 'Test::Siebel::Srvrmgr::Daemon::Action::Serializable';
use Test::Most;

sub recover_me : Test(+1) {

    my $test = shift;

    $test->SUPER::recover_me();

    my $defs = $test->recover( $test->get_dump() );

    is( ref($defs), 'HASH',
        'component definitions were recovered successfuly' );

}

1;

__DATA__
srvrmgr:SUsrvr> list comp def SRProc

CC_NAME                                                                       CT_NAME                                                                       CC_RUNMODE                       CC_ALIAS                         CC_DISP_ENABLE_ST                                              CC_DESC_TEXT                                                                                                                                                                                                                                                 CG_NAME                                                                       CG_ALIAS                         CC_INCARN_NO             
----------------------------------------------------------------------------  ----------------------------------------------------------------------------  -------------------------------  -------------------------------  -------------------------------------------------------------  --------------------------------------------------------------------------------------------------------------------  ----------------------------------------------------------------------------  -------------------------------  -----------------------  
Foo Workflow Monitor Agent                                                    Workflow Monitor Agent                                                        Background                       FOOBAWorkMon                     Active                                                                                                                                                                                                                                                                                                                      Workflow Management                                                           Workflow                         0                        

1 row returned.

