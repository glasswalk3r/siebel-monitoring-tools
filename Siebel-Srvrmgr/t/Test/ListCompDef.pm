package Test::ListCompDef;

use Test::Most;
use Test::Moose 'has_attribute_ok';
use base 'Test::Class';

sub class { 'Siebel::Srvrmgr::ListParser::Output::ListCompDef' }

sub startup : Tests(startup => 1) {

    my $test = shift;
    use_ok $test->class;
}

sub constructor : Tests(5) {

    my $test  = shift;
    my $class = $test->class;

    can_ok( $class, 'new' );

    my @data = <Test::ListCompDef::DATA>;
    close(Test::ListCompDef::DATA);

    ok(
        my $comps = $class->new(
            {
                data_type => 'list_comp_def',
                raw_data  => \@data,
                cmd_line  => 'list comp def Foo'
            }
        ),
        '... and the constructor should succeed'
    );

    isa_ok( $comps, 'Siebel::Srvrmgr::ListParser::Output' );
    isa_ok( $comps, $class, '... and the object it returns' );
    is(
        $comps->get_fields_pattern(),
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

