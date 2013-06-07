package Test::Action::Serializable::ListCompDef;

use base 'Test::Action::Serializable';
use Test::Most;
use Siebel::Srvrmgr::ListParser;
use Storable;

sub class { 'Siebel::Srvrmgr::Daemon::Action::ListCompDef' }

sub recover_me : Test(+1) {

    my $test  = shift;

	$test->SUPER::recover_me();

    my $defs = retrieve($test->get_dump());

    is( ref($defs), 'HASH',
        'component definitions were recovered successfuly' );

}

1;

__DATA__
srvrmgr:SUsrvr> list comp def SRProc

CC_NAME                                                                       CT_NAME                                                                       CC_RUNMODE                       CC_ALIAS                         CC_DISP_ENABLE_ST                                              CC_DESC_TEXT                                                                                                                                                                                                                                                 CG_NAME                                                                       CG_ALIAS                         CC_INCARN_NO             
----------------------------------------------------------------------------  ----------------------------------------------------------------------------  -------------------------------  -------------------------------  -------------------------------------------------------------  --------------------------------------------------------------------------------------------------------------------  ----------------------------------------------------------------------------  -------------------------------  -----------------------  
Foo Workflow Monitor Agent                                                    Workflow Monitor Agent                                                        Background                       BISAOWorkMon                     Active                                                                                                                                                                                                                                                                                                                      Workflow Management                                                           Workflow                         0                        

1 row returned.

