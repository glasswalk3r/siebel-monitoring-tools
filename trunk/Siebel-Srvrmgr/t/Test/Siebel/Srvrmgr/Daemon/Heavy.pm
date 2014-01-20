package Test::Siebel::Srvrmgr::Daemon::Heavy;

use Cwd;
use Test::Most;
use File::Spec;
use Test::Moose 'has_attribute_ok';
use Siebel::Srvrmgr::Daemon::Heavy;
use Config;
use parent 'Test::Siebel::Srvrmgr::Daemon';
use Siebel::Srvrmgr;

sub class_methods : Test(+1) {

    my $test = shift;

    $test->SUPER::class_methods();

    can_ok(
        $test->{daemon},
        (
            'get_commands',    'set_commands',
            'get_bin',         'set_bin',
            'get_write',       'get_read',
            'is_infinite',     'get_last_cmd',
            'get_cmd_stack',   'get_params_stack',
            'get_buffer_size', 'set_buffer_size',
            'get_prompt',      '_set_prompt',
            '_create_child',   '_process_stderr',
            '_process_stdout', '_check_error',
            '_check_child',    '_submit_cmd',
            'close_child',     'has_pid',
            'clear_pid'
        )
    );

}

sub class_attributes : Tests(no_plan) {

    my $test = shift;

    my @attribs = (
        'write_fh',        'read_fh',
        'child_pid',       'is_infinite',
        'last_exec_cmd',   'cmd_stack',
        'params_stack',    'action_stack',
        'ipc_buffer_size', 'srvrmgr_prompt',
        'read_timeout',    'child_pid'
    );

    $test->SUPER::class_attributes(\@attribs);

}

sub runs : Tests(+10) {

    my $test = shift;

    $test->SUPER::runs();

    ok( $test->{daemon}->run(), 'run method executes successfuly' );
    is( $test->{daemon}->get_child_runs(),
        1, 'get_child_runs returns the expected number' );

    my $shifted_cmd;
    ok( $shifted_cmd = $test->{daemon}->shift_commands(),
        'shift_command works' );
    isa_ok( $shifted_cmd, 'Siebel::Srvrmgr::Daemon::Command' );
    ok( $test->{daemon}->shift_commands(), 'shift_command works' );
    ok( $test->{daemon}->shift_commands(), 'shift_command works' );

    ok( $test->{daemon}->run(), 'run method executes successfuly (2)' );
    is( $test->{daemon}->get_child_runs(),
        2, 'get_child_runs returns the expected number' );
    ok( $test->{daemon}->run(), 'run method executes successfuly (3)' );
    is( $test->{daemon}->get_child_runs(),
        3, 'get_child_runs returns the expected number' );

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
			sleep(5);

        }

    }

}

#sub runs_blocked : Test() {
#
#    my $test = shift;
#
#  TODO: {
#
#        local $TODO = 'Usage of alarm must be reviewed';
#
#        $test->{daemon}->set_commands(
#            [
#                Siebel::Srvrmgr::Daemon::Command->new(
#                    command => 'list blockme',
#                    action => 'Dummy'   # this one is to get the initial message
#                ),
#                Siebel::Srvrmgr::Daemon::Command->new(
#                    command => 'list blockme',
#                    action =>
#                      'Dummy'    # this one is to get the "list blockme" message
#                ),
#            ]
#        );
#        dies_ok { $test->{daemon}->run() } 'run method fail due timeout';
#
#    }
#
#}

sub runs_with_stderr : Test(4) {

    my $test = shift;

    $test->{daemon}->set_commands(
        [
            Siebel::Srvrmgr::Daemon::Command->new(
                command => 'list complexquery',
                action  => 'Dummy'
            ),
        ]
    );

    ok( $test->{daemon}->run(), 'run executes OK' );
    ok( $test->_search_log_msg(qr/WARN.*oh\sgod\,\snot\stoday/),
        'can find warn message in the log file' );

    $test->{daemon}->set_commands(
        [
            Siebel::Srvrmgr::Daemon::Command->new(
                command => 'list frag',
                action  => 'Dummy'
            ),
        ]
    );

    dies_ok { $test->{daemon}->run() } 'run dies due fatal error';
    ok(
        $test->_search_log_msg(
            qr/FATAL.*Could\snot\sfind\sthe\sSiebel\sServer/),
        'can find fatal message in the log file'
    );

}

sub _poke_child {

    my $test = shift;

    if (    ( defined( $test->{daemon}->get_pid() ) )
        and ( $test->{daemon}->get_pid() =~ /\d+/ ) )
    {

        unless ( kill 0, $test->{daemon}->get_pid() ) {

            return 0;

        }
        else {

            return 1;

        }

    }
    else {

        return 0;

    }

}

sub terminator : Tests(4) {

    my $test   = shift;
    my $logger = Siebel::Srvrmgr->gimme_logger( $test->class() );

    ok( $test->{daemon}->close_child($logger),
        'close_child returns true (termined child process)' );
    is( $test->{daemon}->close_child($logger),
        0, 'close_child returns false since there is no PID anymore' );
    is( $test->{daemon}->has_pid(), '', 'has_pid returns false' );
    is( $test->_poke_child(),       0,  'child PID is no more' );

    $test->{daemon} = undef;

}

sub _search_log_msg {

    my $test      = shift;
    my $msg_regex = shift;
    my $found     = 0;

    open( my $in, '<', $test->{log_file} )
      or die 'Cannot read ' . $test->{log_file} . ': ' . $! . "\n";

    while (<$in>) {

        chomp();
        if (/$msg_regex/) {

            $found = 1;
            last;

        }

    }

    close($in) or die 'Cannot close ' . $test->{log_file} . ': ' . $! . "\n";

    return $found;

}

1;
