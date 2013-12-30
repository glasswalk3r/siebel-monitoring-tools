package Test::Siebel::Srvrmgr::ListParser::Output::Tabular;

use base 'Test::Siebel::Srvrmgr::ListParser::Output';

# this class cannot have a instance due the methods that must be overrided by subclasses of it

sub get_super {

    return 'Siebel::Srvrmgr::ListParser::Output::Tabular';

}

sub _constructor : Test(no_plan) {

    my $test        = shift;
    my $attribs_ref = shift;

    if ( ( defined($attribs_ref) ) and ( ref($attribs_ref) eq 'HASH' ) ) {

        $test->SUPER::_constructor($attribs_ref);

    }
    else {

        $test->SUPER::_constructor( { structure_type => 'fixed' } );

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

sub class_methods : Test(no_plan) {

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

}

1;
