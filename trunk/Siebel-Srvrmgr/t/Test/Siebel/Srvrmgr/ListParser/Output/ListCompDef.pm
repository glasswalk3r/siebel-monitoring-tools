package Test::Siebel::Srvrmgr::ListParser::Output::ListCompDef;

use Test::Most;
use Test::Moose 'has_attribute_ok';
use base 'Test::Siebel::Srvrmgr';

sub constructor : Tests(+2) {

    my $test = shift;

    ok(
        $test->{compdefs} = $test->class()->new(
            {
                data_type => 'list_comp_def',
                raw_data  => $test->get_my_data(),
                cmd_line  => 'list comp def Foo'
            }
        ),
        'the constructor should succeed'
    );

    isa_ok( $test->{compdefs}, $test->class() );

}

sub class_methods : Tests(+2) {

    my $test = shift;

    isa_ok( $test->{compdefs}, $test->class() );
    is(
        $test->{compdefs}->get_fields_pattern(),
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

