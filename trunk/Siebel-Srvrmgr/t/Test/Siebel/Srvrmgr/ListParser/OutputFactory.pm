package Test::Siebel::Srvrmgr::ListParser::OutputFactory;

use Test::Most;
use parent 'Test::Siebel::Srvrmgr';

sub constructor : Tests(+13) {

    my $test  = shift;
    my $class = $test->class;

    can_ok( $class, qw(create can_create get_mapping) );

    dies_ok {
        my $output =
          $class->create( 'foobar',
            { data_type => 'foobar', raw_data => [], cmd_line => '' } );
    }
    'the create method fail with an invalid class';

    foreach my $type (
        qw(list_servers list_comp list_params list_comp_def greetings list_comp_types load_preferences)
      )
    {

        ok( $class->can_create($type), "$type is a valid type" );

    }

    my $table;

    ok( $table = $class->get_mapping(), 'get_mapping returns something' );

    is( ref($table), 'HASH', 'get_mapping returns an hash ref' );

    my $previous = scalar( keys( %{ $class->get_mapping() } ) );

    ok( delete( $table->{list_comp} ),
        'it is ok to remove keys from the hash ref' );

    is( $previous, scalar( keys( %{ $class->get_mapping() } ) ), 'original mapping stays untouched' );

}

1;
