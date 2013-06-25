package Test::Siebel::Srvrmgr::Daemon;

use Cwd;
use Test::Most;
use File::Spec;
use Test::Moose 'has_attribute_ok';
use Siebel::Srvrmgr::Daemon;
use Config;
use base 'Test::Siebel::Srvrmgr';

sub _constructor : Tests(+2) {

    my $test = shift;

    my $cmd = File::Spec->catfile( getcwd(), 'srvrmgr-mock.pl' );

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
                commands    => [
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

	isa_ok($test->{daemon}, $test->class());

}

sub class_methods : Tests(24) {

    my $test = shift;

    can_ok(
        $test->{daemon},
        (
            'get_server',      'set_server',
            'get_gateway',     'set_gateway',
            'get_enterprise',  'set_enterprise',
            'get_user',        'set_user',
            'get_password',    'set_password',
            'get_wait_time',   'set_wait_time',
            'get_commands',    'set_commands',
            'get_bin',         'set_bin',
            'get_write',       'get_read',
            'is_infinite',     'get_last_cmd',
            'get_cmd_stack',   'get_params_stack',
            '_setup_commands', 'run',
            'DEMOLISH'
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

sub class_attributes : Tests(16) {

    my $test = shift;

    my @attribs = (
        'server',        'gateway',   'enterprise',   'user',
        'password',      'wait_time', 'commands',     'bin',
        'write_fh',      'read_fh',   'pid',          'is_infinite',
        'last_exec_cmd', 'cmd_stack', 'params_stack', 'action_stack'
    );

    foreach my $attribute (@attribs) {

        has_attribute_ok( $test->{daemon}, $attribute );

    }

}

sub runs : Test() {

    my $test  = shift;

    $SIG{INT} = \&clean_up;

    ok( $test->{daemon}->run(), 'run method executes successfuly' );

}

sub runs_blocked : Test() {

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
