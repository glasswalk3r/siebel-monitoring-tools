package Test::Siebel::Srvrmgr::Daemon::Light;

use Test::Most;
use Siebel::Srvrmgr::Daemon;
use Config;
use base 'Test::Siebel::Srvrmgr::Daemon';

sub class_methods : Test(+1) {

    my $test = shift;
    $test->SUPER::class_methods();

    can_ok( $test->{daemon},
        (qw(_del_file _del_input_file _del_output_file _check_system)) );

}

sub class_attributes : Tests {

    my $test    = shift;
    my @attribs = (qw(output_file input_file));
    $test->SUPER::class_attributes( \@attribs );

}

1;
