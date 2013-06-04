package Test::Daemon::RunBlocked;

use Test::Most;
use Config;
use base 'Test::Daemon';

sub class_run : Test(+1) {

    my $test  = shift;
    my $class = $test->class;

    $test->{daemon}->set_commands(
        [
            Siebel::Srvrmgr::Daemon::Command->new(
                command => 'list blockme',
                action => 'Dummy'    # this one is to get the initial message
            ),
            Siebel::Srvrmgr::Daemon::Command->new(
                command => 'list blockme',
                action =>
                  'Dummy'    # this one is to get the "list blockme" message
            ),
        ]
    );

  SKIP: {

        skip 'alarm does not work as expected in Microsoft Windows OS', 1
          if ( $Config{osname} eq 'MSWin32' );

        dies_ok { $test->{daemon}->run() } 'run method fail due timeout';

    }

}

1;
