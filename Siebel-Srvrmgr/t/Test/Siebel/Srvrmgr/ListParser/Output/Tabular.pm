package Test::Siebel::Srvrmgr::ListParser::Output::Tabular;

use base 'Test::Siebel::Srvrmgr::ListParser::Output';
use Test::Most;
use Siebel::Srvrmgr::Regexes qw(SRVRMGR_PROMPT);

sub get_structure_type {

    my $test = shift;

    return $test->{structure_type};

}

sub get_col_sep {

    my $test = shift;
    return $test->{col_sep};

}

sub get_super {

    return 'Siebel::Srvrmgr::ListParser::Output::Tabular';

}

# :WORKAROUND:06-07-2014 00:25:20:: cannot easily change default getter of Class::Data::Inheritable, so creating an alias
sub get_cmd_line {

    my $self = shift;
    $self->get_my_data;
    return __PACKAGE__->cmd_line;

}

# overriding parent's because the files will have the command itself followed by the output of it
sub get_my_data {

    my $test = shift;

    my $data_ref = $test->SUPER::get_my_data();

    my $cmd_line = shift( @{$data_ref} );
    $cmd_line =~ s/@{[SRVRMGR_PROMPT]}/$2/;  # removing the prompt from the data
    __PACKAGE__->mk_classdata( cmd_line => $cmd_line );
    shift( @{$data_ref} );                   # empty line before output

    return $data_ref;

}

sub _constructor : Test(+2) {

    my $test        = shift;
    my $attribs_ref = shift;

    if ( $test->get_col_sep() ) {

        $test->SUPER::_constructor(
            {
                structure_type => $test->get_structure_type(),
                col_sep        => $test->get_col_sep()
            }
        );

    }
    else {

        # this server name is expected from the files used for testing
        $test->SUPER::_constructor(
            {
                structure_type => $test->get_structure_type()
            }
        );

    }

  SKIP: {

        skip $test->class()
          . ' subclass should not cause an exception with new()', 2
          unless ( $test->is_super() );

        dies_ok(
            sub {
                $test->class()->new(
                    {
                        data_type      => $test->get_data_type(),
                        cmd_line       => 'list foo',
                        raw_data       => $test->get_my_data(),
                        structure_type => $test->get_structure_type()
                    }
                );
            },
            $test->get_super() . ' new() causes an exception'
        );

        like( $@, qr/_build_expected/, '_build_expected exception is raised' );

    }

}

sub class_attributes : Test(no_plan) {

    my $test        = shift;
    my $attribs_ref = shift;

    my @attribs = qw (structure_type known_types expected_fields found_header);

    if ( ( defined($attribs_ref) ) and ( ref($attribs_ref) eq 'ARRAY' ) ) {

        foreach my $attrib ( @{$attribs_ref} ) {

            push( @attribs, $attrib );

        }

    }

    $test->SUPER::class_attributes( \@attribs );

}

sub class_methods : Test(+2) {

    my $test        = shift;
    my $methods_ref = shift;

    my @methods =
      qw(_consume_data parse get_known_types get_type get_expected_fields found_header _set_found_header _build_expected);

    if ( ( defined($methods_ref) ) and ( ref($methods_ref) eq 'ARRAY' ) ) {

        foreach my $method ( @{$methods_ref} ) {

            push( @methods, $method );

        }

    }

    $test->SUPER::class_methods( \@methods );

  SKIP: {

        skip $test->get_super() . ' does not have instance for those tests', 2
          if ( $test->is_super() );

        ok( $test->get_output()->set_raw_data( [] ), 'set_raw_data works' );

        dies_ok
          sub { $test->get_output()->parse() },
          'test parse validation 1';

        like( $@, qr/Invalid\sdata\sto\sparse/, 'invalid data to parse' );

        ok(
            $test->get_output()
              ->set_raw_data( [ '', '10 rows returned.', '' ] ),
            'set_raw_data works'
        );

        dies_ok
          sub { $test->get_output()->parse() },
          'test parse validation 2';

        like(
            $@,
            qr/Raw\sdata\sbecame\sinvalid/,
            'raw data became invalid after initial cleanup'
        );

    }

}

1;
