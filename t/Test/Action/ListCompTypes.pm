package Test::Action::ListCompDef;

use base 'Test::Class';
use Test::Most;
use Siebel::Srvrmgr::ListParser;
use Storable;

sub class { 'Siebel::Srvrmgr::Daemon::Action::ListCompDef' }

sub startup : Tests(startup => 1) {
    my $test = shift;
    use_ok $test->class;
}

sub constructor : Tests(6) {

    my $test  = shift;
    my $class = $test->class;

    can_ok( $class,
        qw(new get_params get_parser get_params do get_dump_file set_dump_file)
    );

    my $file = 'list_comp_def.storable';

    my $action;

    ok(
        $action = $class->new(
            {
                parser =>
                  Siebel::Srvrmgr::ListParser->new( { is_warn_enabled => 1 } ),
                params => [$file]
            }
        ),
        'the constructor should suceed'
    );

    is( $action->get_dump_file(),
        $file, 'get_dump_file returns the correct string' );

    ok( $action->set_dump_file($file), 'set_dump_file works' );

    my @data = <Test::Action::ListCompDef::DATA>;
    close(Test::Action::ListCompDef::DATA);

    ok( $action->do( \@data ), 'do methods works fine' );

    my $defs = retrieve($file);

    is( ref($defs), 'HASH',
        'component definitions were recovered successfuly' );

    unlink($file) or die "Cannot remove $file: $!\n";

}

1;

__DATA__
srvrmgr:SUsrvr> list comp def SRProc

CC_NAME                                                                       CT_NAME                                                                       CC_RUNMODE                       CC_ALIAS                         CC_DISP_ENABLE_ST                                              CC_DESC_TEXT                                                                                                                                                                                                                                                 CG_NAME                                                                       CG_ALIAS                         CC_INCARN_NO             
----------------------------------------------------------------------------  ----------------------------------------------------------------------------  -------------------------------  -------------------------------  -------------------------------------------------------------  --------------------------------------------------------------------------------------------------------------------  ----------------------------------------------------------------------------  -------------------------------  -----------------------  
Foo Workflow Monitor Agent                                                    Workflow Monitor Agent                                                        Background                       BISAOWorkMon                     Active                                                                                                                                                                                                                                                                                                                      Workflow Management                                                           Workflow                         0                        

1 row returned.

