package Test::Siebel::Srvrmgr::ListParser::OutputFactory;

use Test::Most;
use base 'Test::Siebel::Srvrmgr';

sub constructor : Tests(+8) {

    my $test  = shift;
    my $class = $test->class;

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
    ok(
        $class->can_create('list_comp_types'),
        'list_comp_types is a valid type'
    );
    ok(
        $class->can_create('load_preferences'),
        'load_preferences is a valid type'
    );

}

1;
