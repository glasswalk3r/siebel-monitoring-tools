package Test::Siebel::Srvrmgr::Daemon::Light;

use Cwd;
use Test::Most;
use File::Spec;
use Test::Moose 'has_attribute_ok';
use Siebel::Srvrmgr::Daemon;
use Config;
use base 'Test::Siebel::Srvrmgr::Daemon';

sub class_methods : Tests(+1) {

    my $test = shift;
    $test->SUPER::class_methods();

    can_ok( $test->{daemon},
        (qw(_del_file _del_input_file _del_output_file _check_system)) );

}

sub class_attributes : Tests(+2) {

    my $test = shift;
    $test->SUPER::class_attributes();

    my @attribs = (qw(output_file input_file));

    foreach my $attribute (@attribs) {

        has_attribute_ok( $test->{daemon}, $attribute );

    }

}

sub runs_much_more : Tests(60) {

    my $test = shift;

  SKIP: {

        skip 'Not a developer machine', 60
          unless ( $ENV{SIEBEL_SRVRMGR_DEVEL} );

        $test->{daemon}->set_commands(
            [
                Siebel::Srvrmgr::Daemon::Command->new(
                    command => 'load preferences',
                    action  => 'LoadPreferences'
                ),
                Siebel::Srvrmgr::Daemon::Command->new(
                    command => 'list comp type',
                    action  => 'ListCompTypes',
                    params  => ['dump1']
                ),
                Siebel::Srvrmgr::Daemon::Command->new(
                    command => 'list comp',
                    action  => 'ListComps',
                    params  => ['dump2']
                ),
                Siebel::Srvrmgr::Daemon::Command->new(
                    command => 'list comp def',
                    action  => 'ListCompDef',
                    params  => ['dump3']
                )
            ]
        );

        for ( 1 .. 60 ) {

            ok( $test->{daemon}->run(), 'run method executes successfuly' );

        }

    }

}

1;
