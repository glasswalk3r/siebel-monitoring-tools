package Test::Action;

use Test::Most;
use Siebel::Srvrmgr::ListParser;
use Test::Moose 'has_attribute_ok';
use base 'Test::Class';

sub class { 'Siebel::Srvrmgr::Daemon::Action' }

sub startup : Tests(startup => 1) {
    my $test = shift;
    use_ok $test->class;
}

sub constructor : Tests(8) {

    my $test  = shift;
    my $class = $test->class;

    can_ok( $class, qw(new get_params get_parser get_params do) );

    my $action;

    ok(
        $action = $class->new(
            {
                parser =>
                  Siebel::Srvrmgr::ListParser->new( { is_warn_enabled => 1 } ),
                params => ['foobar']
            }
        ),
        'the constructor should suceed'
    );

	has_attribute_ok($action, 'parser');
	has_attribute_ok($action, 'params');

    isa_ok( $action->get_parser(), 'Siebel::Srvrmgr::ListParser',
        'get_parser returned object' );

    my @data = qw(foo bar something);

    ok( $action->do( \@data ), 'do method works with an array reference' );

    dies_ok( sub { $action->do('simple string') },
        'do method raises an exception with wrong type of parameter' );

    my $params_ref = $action->get_params();

    is( $params_ref->[0], 'foobar', 'get_params returns the correct content' );

}

1;
