package Test::Siebel::Srvrmgr::ListParser::Output;

use Test::Most;
use Test::Moose 'has_attribute_ok';
use Hash::Util qw(lock_keys);
use base 'Test::Siebel::Srvrmgr';

sub get_super {

    return 'Siebel::Srvrmgr::ListParser::Output';

}

sub is_super {

    my $test = shift;

    return ( $test->class() eq $test->get_super() ) ? 1 : 0;

}

sub get_data_type {

    return 'output';

}

sub get_cmd_line {

    return 'undefined';
}

sub get_output {

    my $test = shift;

    return $test->{output};

}

# after setting the Siebel::Srvrgmr::ListParser::Output instance,
# use lock_keys to avoid subclasses to create their own references of instances
sub set_output {

    my $test  = shift;
    my $value = shift;

    die "Invalid parameter for set_output"
      unless ( $value->isa( $test->get_super() ) );

    $test->{output} = $value;

    lock_keys( %{$test} );

    return 1;

}

# forcing to be the first method to be tested
# this predates the usage of setup and startup, but the first is expensive and the second cannot be used due parent class
sub _constructor : Tests(3) {

    my $test = shift;

  SKIP: {

        skip $test->class()
          . ' is an abstract class and cannot have an instance ', 2
          if ( $test->is_super() );

        ok(
            $test->set_output(
                $test->class()->new(
                    {
                        data_type => $test->get_data_type(),
                        cmd_line  => $test->get_cmd_line(),
                        raw_data  => $test->get_my_data()
                    }
                )
            ),
            'the constructor should succeed'
        );

        isa_ok( $test->get_output(), $test->class() );

    }

  SKIP: {

        skip $test->class()
          . ' subclass should not cause an exception with new()', 1
          unless ( $test->is_super() );

        dies_ok(
            sub {

                $test->class()->new(
                    {
                        data_type => $test->get_data_type(),
                        cmd_line  => $test->get_cmd_line(),
                        raw_data  => $test->get_my_data()
                    }
                );
            },
            $test->get_super() . ' new() causes an exception'
        );

    }

}

sub class_attributes : Tests(8) {

    my $test = shift;

    my @attribs = (
        'data_type',      'raw_data',     'data_parsed', 'cmd_line',
        'fields_pattern', 'header_regex', 'col_sep',     'header_cols'
    );

    foreach my $attrib (@attribs) {

        has_attribute_ok( $test->get_test_item(), $attrib );

    }

}

# this method returns an Siebel::Srvrmgr::ListParser::Output object or the class name
# if the instance does not exists
sub get_test_item {

    my $test = shift;

    if ( defined( $test->get_output() )
        and $test->get_output()->isa( $test->class() ) )
    {

        return $test->get_output();

    }
    else {

        return $test->class();

    }

}

sub class_methods : Tests(12) {

    my $test = shift;

    my @methods = (
        'get_data_type',      'get_raw_data',
        'set_raw_data',       'get_data_parsed',
        'set_data_parsed',    'get_cmd_line',
        'get_fields_pattern', '_set_fields_pattern',
        'get_header_regex',   '_set_col_sep',
        'get_col_sep',        '_set_header_regex',
        'get_header_cols',    'set_header_cols',
        'parse',              '_split_fields',
        '_set_header',        '_parse_data',
        '_set_header_regex',  'BUILD', 
		'_define_pattern'
    );

    can_ok( $test->get_test_item(), @methods );

  SKIP: {

        skip $test->get_super() . ' does not have instance for those tests', 11
          if ( $test->is_super() );

        is(
            $test->get_output()->get_data_type(),
            $test->get_data_type(),
            'get_data_type() returns the correct value'
        );

        is( ref( $test->get_output()->get_raw_data() ),
            'ARRAY', 'get_raw_data() returns a array reference' );

        ok(
            $test->get_output()->set_raw_data( $test->get_my_data() ),
            'set_raw_data accepts an array reference as parameter'
        );

        is( ref( $test->get_output()->get_data_parsed() ),
            'HASH', 'get_data_parsed returns an hash reference' );

        my $old_ref = $test->get_output()->get_data_parsed();

        ok(
            $test->get_output()
              ->set_data_parsed( { one => 'value', two => 100 } ),
            'set_data_parsed accepts an hash reference as parameter'
        );

        # restore the original value
        $test->get_output()->set_data_parsed($old_ref);

        is( $test->get_output()->get_cmd_line(),
            $test->get_cmd_line(), 'get_cmd_line returns the correct string' );

        # simple tests
        foreach my $method (
            qw(get_fields_pattern get_header_regex get_col_sep get_header_cols)
          )
        {

            ok( $test->get_output()->$method(), "$method() returns true" );

        }

# :TODO      :01/07/2013 14:06:16:: test returned values from methods above
# :TODO      :01/07/2013 14:06:16:: test "hidden" methods _set_header and _split_fields

    }

}

1;
