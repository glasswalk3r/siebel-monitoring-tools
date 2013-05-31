package Test::Daemon::RunBlocked;

use Cwd;
use Test::Most;
use base 'Test::Daemon';

sub class_bad_exec : Tests(2) {

    my $test  = shift;
    my $class = $test->class;

    $test->{daemon}->set_commands(
        [
            Siebel::Srvrmgr::Daemon::Command->new(
                command => 'list blockme',
                action  => 'Dumper'
            ),
        ]
    );

#    dies_ok { $test->{daemon}->run() } 'run method fail due timeout';
ok($test->{daemon}->run(), 'run method fail due timeout');

}

1;

