package Test::Siebel::Srvrmgr::ListParser::Output;

use Test::Most;
use Test::Moose 'has_attribute_ok';
use base 'Test::Siebel::Srvrmgr';

# forcing to be the first method to be tested
# this predates the usage of setup and startup, but the first is expensive and the second cannot be used due parent class

sub get_super {

    return 'Siebel::Srvrmgr::ListParser::Output';

}

sub is_super {

    my $test = shift;

    return ( $test->class() eq $test->get_super() ) ? 1 : 0;

}

sub get_type {

    return 'output';

}

sub get_cmd_line {

    return 'undefined';
}

sub _constructor : Tests(3) {

    my $test = shift;

  SKIP: {

        skip $test->class()
          . ' is an abstract class and cannot have an instance ', 2
          if ( $test->is_super() );

        ok(
            $test->{output} = $test->class()->new(
                {
                    data_type => $test->get_type(),
                    cmd_line  => $test->get_cmd_line(),
                    raw_data  => $test->get_my_data()
                }
            ),
            'the constructor should succeed'
        );

        isa_ok( $test->{output}, $test->class() );

    }

  SKIP: {

        skip $test->class()
          . ' subclass should not cause an exception with new()', 1
          unless ( $test->is_super() );

        dies_ok(
            sub {

                $test->class()->new(
                    {
                        data_type => $test->get_type(),
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

sub get_test_item {

    my $test = shift;

    if ( defined( $test->{output} ) and $test->{output}->isa( $test->class() ) )
    {

        return $test->{output};

    }
    else {

        return $test->class();

    }

}

sub class_methods : Tests(13) {

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
        '_set_header_regex',  'BUILD'
    );

    can_ok( $test->get_test_item(), @methods );

  SKIP: {

        skip $test->get_super() . ' does not have instance for those tests', 3
          if ( $test->is_super() );

        is(
            $test->{output}->get_data_type(),
            $test->get_data_type(),
            'get_data_type() returns the correct value'
        );

        is( ref( $test->{output}->get_raw_data() ),
            'ARRAY', 'get_raw_data() returns a array reference' );

        ok(
            $test->{output}->set_raw_data( $test->get_my_data() ),
            'set_raw_data accepts an array reference as parameter'
        );

        is( ref( $test->{output}->get_data_parsed() ),
            'HASH', 'get_data_parsed returns an hash reference' );

        ok(
            $test->{output}->set_data_parsed( { one => 'value', two => 100 } ),
            'set_data_parsed accepts an hash reference as parameter'
        );

        ok( $test->{output}->set_content( $test->get_my_data()->[0] ),
            'is ok to add lines to it' );

        is( $test->{output}->get_cmd_line(), $test->get_cmd_line() );

        # simple tests
        foreach my $method (
            qw(get_fields_pattern get_header_regex get_col_sep get_header_cols parse)
          )
        {

            ok( $test->{output}->$method(), "$method() works" );

        }

    }

}

1;

__DATA__
Siebel Enterprise Applications Siebel Server Manager, Version 7.5.3 [16157] LANG_INDEPENDENT 
Copyright (c) 2001 Siebel Systems, Inc.  All rights reserved.

This software is the property of Siebel Systems, Inc., 2207 Bridgepointe Parkway,
San Mateo, CA 94404.

User agrees that any use of this software is governed by: (1) the applicable
user limitations and other terms and conditions of the license agreement which
has been entered into with Siebel Systems or its authorized distributors; and
(2) the proprietary and restricted rights notices included in this software.

WARNING: THIS COMPUTER PROGRAM IS PROTECTED BY U.S. AND INTERNATIONAL LAW.
UNAUTHORIZED REPRODUCTION, DISTRIBUTION OR USE OF THIS PROGRAM, OR ANY PORTION
OF IT, MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES, AND WILL BE
PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.

If you have received this software in error, please notify Siebel Systems
immediately at (650) 295-5000.

Type "help" for list of commands, "help <topic>" for detailed help

Connected to 1 server(s) out of a total of 1 server(s) in the enterprise

srvrmgr:>
