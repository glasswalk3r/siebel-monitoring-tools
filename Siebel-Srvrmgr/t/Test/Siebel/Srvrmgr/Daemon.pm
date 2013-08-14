package Test::Siebel::Srvrmgr::Daemon;

use Cwd;
use Test::Most;
use File::Spec;
use Test::Moose 'has_attribute_ok';
use Siebel::Srvrmgr::Daemon;
use Config;
use base 'Test::Siebel::Srvrmgr';

sub _set_log {

    my $test = shift;

    my $log_file = File::Spec->catfile( getcwd(), 'daemon.log' );
    my $log_cfg  = File::Spec->catfile( getcwd(), 'log4perl.cfg' );

    my $config = <<BLOCK;
log4perl.logger.Siebel.Srvrmgr.Daemon = DEBUG, LOG1
log4perl.appender.LOG1 = Log::Log4perl::Appender::File
log4perl.appender.LOG1.filename  = $log_file
log4perl.appender.LOG1.mode = clobber
log4perl.appender.LOG1.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.LOG1.layout.ConversionPattern = %d %p> %F{1}:%L %M - %m%n
BLOCK

    open( my $out, '>', $log_cfg ) or die "Cannot create $log_cfg: $!\n";
    print $out $config;
    close($out) or die "Could not close $log_cfg: $!\n";

    $ENV{SIEBEL_SRVRMGR_DEBUG} = $log_cfg;

    $test->{log_file} = $log_file;

}

sub _constructor : Tests(+2) {

    my $test = shift;

    my $cmd = File::Spec->catfile( getcwd(), 'srvrmgr-mock.pl' );
    $test->_set_log();

# this data structure will make more sense when saw in use by the following foreach loop
    $test->{test_data} = [
        [qw(get_server set_server foo)],
        [qw(get_gateway set_gateway bar)],
        [qw(get_enterprise set_enterprise foobar)],
        [qw(get_user set_user sadmin)],
        [qw(get_password set_password my_pass)],
        [ 'get_bin', 'set_bin', $cmd ],
        [ qw(get_wait_time set_wait_time 1)
        ] # :TRICKY:29/2/2012 17:50:36:: set_wait_time will return the value passed as parameter, so the ok function will complain if passed 0
    ];

    ok(
        $test->{daemon} = $test->class()->new(
            {
                server      => $test->{test_data}->[0]->[2],
                gateway     => $test->{test_data}->[1]->[2],
                enterprise  => $test->{test_data}->[2]->[2],
                user        => $test->{test_data}->[3]->[2],
                password    => $test->{test_data}->[4]->[2],
                bin         => $test->{test_data}->[5]->[2],
                is_infinite => 0,
                wait_time   => $test->{test_data}->[6]->[2],
                use_perl    => 1
                , # important to avoid calling another interpreter besides perl when invoked by IPC::Open3
                commands => [
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
            }
        ),
        '... and the constructor should succeed'
    );

    isa_ok( $test->{daemon}, $test->class() );

}

sub class_methods : Tests(24) {

    my $test = shift;

    can_ok(
        $test->{daemon},
        (
            'get_server',        'set_server',
            'get_gateway',       'set_gateway',
            'get_enterprise',    'set_enterprise',
            'get_user',          'set_user',
            'get_password',      'set_password',
            'get_wait_time',     'set_wait_time',
            'get_commands',      'set_commands',
            'get_bin',           'set_bin',
            'get_write',         'get_read',
            'is_infinite',       'get_last_cmd',
            'get_cmd_stack',     'get_params_stack',
            '_setup_commands',   'run',
            'DEMOLISH',          'shift_commands',
            'set_child_timeout', 'get_child_timeout',
            'use_perl',          'get_buffer_size',
            'set_buffer_size',   'get_lang_id',
            'set_lang_id',       'get_child_runs',
            '_set_child_runs',   'get_prompt',
            '_set_prompt',       'shift_commands',
            '_create_child',     '_process_stderr',
            '_process_stdout',   '_check_error',
            '_check_child',      '_term_INT',
            '_term_PIPE',        '_term_ALARM',
            '_gimme_logger',     '_submit_cmd',
            '_close_child'
        )
    );

    ok( $test->{daemon}->_setup_commands(), '_setup_commands works' );
    is( $test->{daemon}->is_infinite(), 0, 'is_infinite must return false' );

    foreach my $attrib ( @{ $test->{test_data} } ) {

        my $get = $attrib->[0];
        my $set = $attrib->[1];

        is( $test->{daemon}->$get(),
            $attrib->[2], "$get returns the correct string" );
        ok( $test->{daemon}->$set( $attrib->[2] ), "$set works" );
        is( $test->{daemon}->$get(),
            $attrib->[2], "$get returns the correct string after change" );

    }

}

sub class_attributes : Tests(22) {

    my $test = shift;

    my @attribs = (
        'server',        'gateway',   'enterprise',      'user',
        'password',      'wait_time', 'commands',        'bin',
        'write_fh',      'read_fh',   'pid',             'is_infinite',
        'last_exec_cmd', 'cmd_stack', 'params_stack',    'action_stack',
        'child_timeout', 'use_perl',  'ipc_buffer_size', 'lang_id',
        'child_runs', 'srvrmgr_prompt'
    );

    foreach my $attribute (@attribs) {

        has_attribute_ok( $test->{daemon}, $attribute );

    }

}

sub runs : Tests(7) {

    my $test = shift;

    $SIG{INT} = \&clean_up;

    ok( $test->{daemon}->run(), 'run method executes successfuly' );

    my $shifted_cmd;
    ok( $shifted_cmd = $test->{daemon}->shift_commands(),
        'shift_command works' );
    isa_ok( $shifted_cmd, 'Siebel::Srvrmgr::Daemon::Command' );
    ok( $test->{daemon}->shift_commands(), 'shift_command works' );
    ok( $test->{daemon}->shift_commands(), 'shift_command works' );

    ok( $test->{daemon}->run(), 'run method executes successfuly (2)' );
    ok( $test->{daemon}->run(), 'run method executes successfuly (3)' );

}

sub runs_blocked : Test() {

    my $test = shift;

  TODO: {

        local $TODO = 'Usage of alarm must be reviewed';

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

    }

}

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

sub clean_up : Test(shutdown) {

    my $test = shift;

    # removes the dump files
    my $dir = getcwd();

    opendir( DIR, $dir ) or die "Cannot read $dir: $!\n";
    my @files = readdir(DIR);
    close(DIR);

    foreach my $file (@files) {

        if ( $file =~ /^dump\w/ ) {

            unlink $file or warn "Cannot remove $file: $!\n";

        }

    }

}

1;
