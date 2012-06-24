package Test::ActionStash;

use Test::Most;
use Siebel::Srvrmgr::ListParser;
use base 'Test::Class';

sub class { 'Siebel::Srvrmgr::Daemon::ActionStash' }

sub startup : Tests(startup => 1) {
    my $test = shift;
    use_ok $test->class;
}

sub constructor : Tests(7) {

    my $test  = shift;
    my $class = $test->class;

    can_ok( $class, qw(new get_stash set_stash) );

    my $stash;
    my $stash_param;

    ok( $stash = $class->new(), 'the constructor should succeed' );

    dies_ok(
        sub {
            $stash_param = $class->new( { key1 => 'value', key2 => 'value' } );
        },
        'the constructor should die because there is already an instance of it'
    );

    isa_ok( $stash->get_stash(), 'ARRAY',
        'get_stash returns an array reference' );

    dies_ok( sub { $stash->set_stash('simple string') },
        'set_stash method raises an exception with wrong type of parameter' );

    ok(
        $stash->set_stash( { key1 => 'value', key2 => 4 } ),
        'set_stash works with the correct parameter type'
    );

    isa_ok( $stash->get_stash(),
        'HASH', 'get_stash returns a hash reference' );

}

1;
