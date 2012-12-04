package Test::Daemon;

use Cwd;
use Test::Most;
use File::Spec;
use base 'Test::Class';

sub class { 'Siebel::Srvrmgr::Daemon' }

sub startup : Tests(startup => 1) {

    my $test = shift;
    use_ok $test->class;
}

sub constructor : Tests(27) {

    my $test  = shift;
    my $class = $test->class;

    can_ok( $class, 'new' );

    #extended method tests
    can_ok(
        $class,
        (
            'get_server',     'set_server',
            'get_gateway',    'set_gateway',
            'get_enterprise', 'set_enterprise',
            'get_user',       'set_user',
            'get_password',   'set_password',
            'get_wait_time',  'set_wait_time',
            'get_commands',   'set_commands',
            'get_bin',        'set_bin',
            'get_write',      'get_read',
            'is_infinite',    'get_last_cmd',
            'get_cmd_stack',  'get_params_stack',
            'setup_commands', 'BUILD',
            'run',            'DEMOLISH'
        )
    );

    my $comp_types_file = 'dump1';
    my $comps_file      = 'dump2';
    my $comps_defs_file = 'dump3';

    my $is_infinite = 0;

    my $cmd = File::Spec->catfile( getcwd(), 't', 'srvrmgr-mock.pl' );

# this data structure will make more sense when saw in use by the following foreach loop
    my @data = (
        [qw(get_server set_server foo)],
        [qw(get_gateway set_gateway bar)],
        [qw(get_enterprise set_enterprise foobar)],
        [qw(get_user set_user sadmin)],
        [qw(get_password set_password my_pass)],
        [ 'get_bin', 'set_bin', $cmd ],
        [ qw(get_wait_time set_wait_time 1)
        ] # :TRICKY:29/2/2012 17:50:36:: set_wait_time will return the value passed as parameter, so the ok function will complain if passed 0
    );

    ok(
        my $daemon = $class->new(
            {
                server      => $data[0]->[2],
                gateway     => $data[1]->[2],
                enterprise  => $data[2]->[2],
                user        => $data[3]->[2],
                password    => $data[4]->[2],
                bin         => $data[5]->[2],
                is_infinite => $is_infinite,
                wait_time   => $data[6]->[2],
                commands    => [
                    Siebel::Srvrmgr::Daemon::Command->new(
                        command => 'load preferences',
                        action  => 'LoadPreferences'
                    ),
                    Siebel::Srvrmgr::Daemon::Command->new(
                        command => 'list comp type',
                        action  => 'ListCompTypes',
                        params  => [$comp_types_file]
                    ),
                    Siebel::Srvrmgr::Daemon::Command->new(
                        command => 'list comp',
                        action  => 'ListComps',
                        params  => [$comps_file]
                    ),
                    Siebel::Srvrmgr::Daemon::Command->new(
                        command => 'list comp def',
                        action  => 'ListCompDef',
                        params  => [$comps_defs_file]
                    )
                ]
            }
        ),
        '... and the constructor should succeed'
    );

    foreach my $attrib (@data) {

        my $get = $attrib->[0];
        my $set = $attrib->[1];

        is( $daemon->$get(), $attrib->[2], "$get returns the correct string" );
        ok( $daemon->$set( $attrib->[2] ), "$set works" );
        is( $daemon->$get(), $attrib->[2],
            "$get returns the correct string after change" );

    }

    is( $daemon->is_infinite(), 0, 'is_infinite must return false' );

    ok( $daemon->setup_commands(), 'setup_commands works' );

    ok( $daemon->run(), 'run method executes successfuly' );

    # removes the dump files
    my $dir = getcwd();

    opendir( DIR, $dir ) or die "Cannot read $dir: $!\n";
    my @files = readdir(DIR);
    close(DIR);

    foreach my $file (@files) {

        if ( $file =~ /^dump\w/ ) {

            unlink $file or die "Cannot remove $file: $!\n";

        }

    }

}

1;

