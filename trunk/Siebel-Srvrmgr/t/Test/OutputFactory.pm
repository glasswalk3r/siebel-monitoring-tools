package Test::OutputFactory;

use Test::Most;
use base 'Test::Class';

sub class { 'Siebel::Srvrmgr::ListParser::OutputFactory' }

sub startup : Tests(startup => 1) {
    my $test = shift;
    use_ok $test->class;
}

sub constructor : Tests(9) {

    my $test  = shift;
    my $class = $test->class;

    can_ok( $class, 'new' );

    can_ok( $class, 'create' );

    dies_ok {
        my $output =
          $class->create( 'foobar',
            { data_type => 'foobar', raw_data => [], cmd_line => '' } );
    }
    'the create method fail with an invalid class';

    ok( $class->can_create('list_comp'),     'list_comp is a valid type' );
    ok( $class->can_create('list_params'),   'list_params is a valid type' );
    ok( $class->can_create('list_comp_def'), 'list_comp_def is a valid type' );
    ok( $class->can_create('greetings'),     'greetings is a valid type' );
    ok( $class->can_create('list_comp_types'),
        'list_comp_types is a valid type' );
    ok(
        $class->can_create('load_preferences'),
        'load_preferences is a valid type'
    );

}

1;
