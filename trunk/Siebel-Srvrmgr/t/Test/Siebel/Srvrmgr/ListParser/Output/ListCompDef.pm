package Test::Siebel::Srvrmgr::ListParser::Output::ListCompDef;

use Test::Most;
use Test::Moose 'has_attribute_ok';
use base 'Test::Siebel::Srvrmgr::ListParser::Output';

sub class_methods : Tests(+3) {

    my $test = shift;

    isa_ok( $test->get_output(), $test->class() );
    is(
        $test->get_output()->get_fields_pattern(),
        'A78A78A33A33A63A253A78A33A25',
        'fields_patterns is correct'
    );

    my $expected = {
        'Foo Workflow Monitor Agent' => {
            'CT_NAME'           => 'Workflow Monitor Agent',
            'CG_NAME'           => 'Workflow Management',
            'CC_INCARN_NO'      => '0',
            'CC_DISP_ENABLE_ST' => 'Active',
            'CC_NAME'           => 'Foo Workflow Monitor Agent',
            'CG_ALIAS'          => 'Workflow',
            'CC_RUNMODE'        => 'Background',
            'CC_ALIAS'          => 'FOOBAWorkMon',
            'CC_DESC_TEXT'      => ''
        }
    };

    is_deeply( $test->get_output()->get_data_parsed(),
        $expected, 'get_parsed_data returns the correct data structure' );

}

1;

__DATA__
CC_NAME                                                                       CT_NAME                                                                       CC_RUNMODE                       CC_ALIAS                         CC_DISP_ENABLE_ST                                              CC_DESC_TEXT                                                                                                                                                                                                                                                 CG_NAME                                                                       CG_ALIAS                         CC_INCARN_NO             
----------------------------------------------------------------------------  ----------------------------------------------------------------------------  -------------------------------  -------------------------------  -------------------------------------------------------------  --------------------------------------------------------------------------------------------------------------------  ----------------------------------------------------------------------------  -------------------------------  -----------------------  
Foo Workflow Monitor Agent                                                    Workflow Monitor Agent                                                        Background                       FOOBAWorkMon                     Active                                                                                                                                                                                                                                                                                                                      Workflow Management                                                           Workflow                         0                        

1 row returned.

