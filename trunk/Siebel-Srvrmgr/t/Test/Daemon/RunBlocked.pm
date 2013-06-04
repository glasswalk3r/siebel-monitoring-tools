package Test::Daemon::RunBlocked;

use Cwd;
use Test::Most;
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

    dies_ok { $test->{daemon}->run() } 'run method fail due timeout';

}

sub _terminate {

    BAIL_OUT('Got a SIGALRM signal due timeout');

}

1;

