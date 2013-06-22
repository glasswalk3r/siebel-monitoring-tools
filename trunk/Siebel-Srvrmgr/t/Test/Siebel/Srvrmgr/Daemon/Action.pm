package Test::Siebel::Srvrmgr::Daemon::Action;

use Test::Most;
use Siebel::Srvrmgr::ListParser;
use Test::Moose 'has_attribute_ok';
use base 'Test::Siebel::Srvrmgr';

sub get_my_data {

    return [qw(foo bar something)];

}

sub before : Tests(setup) {

    my $test = shift;

    # keeps the subclass of Siebel::Srvrmgr::Daemon as an attribute
    $test->{action} = $test->class()->new(
        {
            parser => Siebel::Srvrmgr::ListParser->new(),
            params => ['foobar']
        }
    );

}

sub constructor : Tests(2) {

    my $test = shift;

    ok( $test->{action}, 'the constructor works' );
    isa_ok( $test->{action}, $test->class() );

}

sub class_attributes : Tests(2) {

    my $test = shift;

    foreach my $attrib (qw(parser params)) {

        has_attribute_ok( $test->{action}, $attrib );

    }

}

sub class_methods : Tests(6) {

    my $test = shift;

    my $parser_class = 'Siebel::Srvrmgr::ListParser';

    isa_ok( $test->{action}->get_parser(),
        $parser_class, "get_parser returns a $parser_class instance" );

    can_ok( $test->{action}, qw(new get_params get_parser get_params do) );

    ok(
        $test->{action}->do( $test->get_my_data() ),
        'do method works with get_my_data() method return'
    );

    is( $test->{action}->do( $test->get_my_data() ),
        1, 'do method returns 1 if output is used' );

    dies_ok( sub { $test->{action}->do('simple string') },
        'do method raises an exception with wrong type of parameter' );

    ok( $test->{action}->get_params(), 'get_params works returns data' );

}

1;
