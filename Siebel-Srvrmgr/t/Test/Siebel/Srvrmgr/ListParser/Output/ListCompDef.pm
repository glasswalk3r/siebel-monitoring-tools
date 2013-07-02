package Test::Siebel::Srvrmgr::ListParser::Output::ListCompDef;

use Test::Most;
use Test::Moose 'has_attribute_ok';
use base 'Test::Siebel::Srvrmgr::ListParser::Output';

sub class_methods : Tests(+2) {

    my $test = shift;

    isa_ok( $test->get_output(), $test->class() );
    is(
        $test->get_output()->get_fields_pattern(),
        'A78A78A33A33A63A118A78A33A25',
        'fields_patterns is correct'
    );

}

1;

__DATA__
CC_NAME                                                                       CT_NAME                                                                       CC_RUNMODE                       CC_ALIAS                         CC_DISP_ENABLE_ST                                              CC_DESC_TEXT                                                                                                                                                                                                                                                 CG_NAME                                                                       CG_ALIAS                         CC_INCARN_NO             
----------------------------------------------------------------------------  ----------------------------------------------------------------------------  -------------------------------  -------------------------------  -------------------------------------------------------------  --------------------------------------------------------------------------------------------------------------------  ----------------------------------------------------------------------------  -------------------------------  -----------------------  
Foo Workflow Monitor Agent                                                    Workflow Monitor Agent                                                        Background                       BISAOWorkMon                     Active                                                                                                                                                                                                                                                                                                                      Workflow Management                                                           Workflow                         0                        

1 row returned.

