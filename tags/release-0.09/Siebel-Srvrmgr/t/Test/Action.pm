package Test::Action;

use Test::Most;
use Siebel::Srvrmgr::ListParser;
use Test::Moose 'has_attribute_ok';
use base 'Test::Class';

sub class { 'Siebel::Srvrmgr::Daemon::Action' }

sub startup : Tests(startup => 2) {

    my $test = shift;
    use_ok $test->class;

    ok(
        $test->{action} = $test->class()->new(
            {
                parser => Siebel::Srvrmgr::ListParser->new(),
                params => ['foobar']
            }
        ),
        'the constructor should succeed'
    );

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
        $parser_class, "get_parser returns a $parser_class object" );

    can_ok( $test->class(), qw(new get_params get_parser get_params do) );

    my @data = qw(foo bar something);

    ok( $test->{action}->do( \@data ),
        'do method works with an array reference' );

    is( $test->{action}->do( \@data ),
        1, 'do method returns 1 if output is used' );

    dies_ok( sub { $test->{action}->do('simple string') },
        'do method raises an exception with wrong type of parameter' );

    my $params_ref = $test->{action}->get_params();

    is( $params_ref->[0], 'foobar', 'get_params returns the correct content' );

}

1;
