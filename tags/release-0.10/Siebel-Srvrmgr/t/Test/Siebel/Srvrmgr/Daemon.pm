package Test::Siebel::Srvrmgr::Daemon;

use Cwd;
use Test::Most;
use File::Spec;
use Test::Moose 'has_attribute_ok';
use Siebel::Srvrmgr::Daemon;
use Siebel::Srvrmgr::Daemon::Command;
use Log::Log4perl;
use base 'Test::Siebel::Srvrmgr';
use Siebel::Srvrmgr;

$SIG{INT} = \&clean_up;

sub _set_log {

    my $test = shift;

    my $log_file = File::Spec->catfile( getcwd(), 'daemon.log' );
    $test->{log_cfg} = File::Spec->catfile( getcwd(), 'log4perl.cfg' );

    my $config = <<BLOCK;
log4perl.logger.Siebel.Srvrmgr.Daemon = WARN, LOG1
log4perl.appender.LOG1 = Log::Log4perl::Appender::File
log4perl.appender.LOG1.filename  = $log_file
log4perl.appender.LOG1.mode = clobber
log4perl.appender.LOG1.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.LOG1.layout.ConversionPattern = %d %p> %F{1}:%L %M - %m%n
BLOCK

    open( my $out, '>', $test->{log_cfg} )
      or die 'Cannot create ' . $test->{log_cfg} . ": $!\n";
    print $out $config;
    close($out) or die 'Could not close ' . $test->{log_cfg} . ": $!\n";

    $ENV{SIEBEL_SRVRMGR_DEBUG} = $test->{log_cfg};
    $test->{log_file} = $log_file;

}

sub _constructor : Tests(+2) {

    my $test = shift;
    $test->_set_log();

  SKIP: {

        skip 'superclass does not have a implementation of _setup_commands', 2
          if ( $test->class() eq 'Siebel::Srvrmgr::Daemon' );

# this data structure will make more sense when saw in use by the following foreach loop
        $test->{test_data} = [
            [qw(get_server set_server foo)],
            [qw(get_gateway set_gateway bar)],
            [qw(get_enterprise set_enterprise foobar)],
            [qw(get_user set_user sadmin)],
            [qw(get_password set_password my_pass)],
            [
                'get_bin', 'set_bin',
                File::Spec->catfile( getcwd(), 'srvrmgr-mock.pl' )
            ]
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

    }    # end of SKIP

    $test->{daemon} = $test->class()
      unless ( ( defined( $test->{daemon} ) )
        and ( $test->{daemon}->isa( $test->class() ) ) );

}

sub class_methods : Tests(22) {

    my $test = shift;

    can_ok(
        $test->{daemon},
        (
            'get_server',     'set_server',
            'get_gateway',    'set_gateway',
            'get_enterprise', 'set_enterprise',
            'get_user',       'set_user',
            'get_password',   'set_password',
            'get_commands',   'set_commands',
            'get_bin',        'set_bin',
            'is_infinite',    '_setup_commands',
            'run',            'DEMOLISH',
            'shift_commands', 'use_perl',
            'get_lang_id',    'set_lang_id',
            'get_child_runs', '_set_child_runs',
            'shift_commands', '_check_error',
            '_check_cmd'
        )
    );

  SKIP: {

        skip 'superclass cannot run this command', 21
          if ( $test->class() eq 'Siebel::Srvrmgr::Daemon' );

        ok( $test->{daemon}->_setup_commands(), '_setup_commands works' );

        is( $test->{daemon}->is_infinite(), 0,
            'is_infinite must return false' );

        foreach my $attrib ( @{ $test->{test_data} } ) {

            my $get = $attrib->[0];
            my $set = $attrib->[1];

            is( $test->{daemon}->$get(),
                $attrib->[2], "$get returns the correct string" );
            ok( $test->{daemon}->$set( $attrib->[2] ), "$set works" );
            is( $test->{daemon}->$get(),
                $attrib->[2], "$get returns the correct string after change" );

        }

        isa_ok( Siebel::Srvrmgr->gimme_logger( $test->class() ),
            'Log::Log4perl::Logger' );

    }

}

sub class_attributes : Tests(11) {

    my $test = shift;

    my @attribs = (
        'server',   'gateway',  'enterprise', 'user',
        'password', 'commands', 'bin',        'is_infinite',
        'use_perl', 'lang_id',  'child_runs'
    );

    foreach my $attribute (@attribs) {

        has_attribute_ok( $test->{daemon}, $attribute );

    }

}

sub runs : Test() {

    my $test = shift;

  SKIP: {

        skip 'run method dies only with superclass', 1
          if ( ref( $test->{daemon} ) ne 'Siebel::Srvrmgr::Daemon' );

        dies_ok { $test->{daemon}->run() } 'run is expected to die';

    }

}

sub clean_up : Test(shutdown) {

    my $test = shift;

    # removes the dump files
    my $dir = getcwd();
    my @files;

    opendir( DIR, $dir ) or die "Cannot read $dir: $!\n";

    while ( readdir(DIR) ) {

        if ( defined($_) ) {

            push( @files, $_ ) if (/^dump\w/);

        }

    }

    close(DIR);

    push( @files, $test->{log_cfg} );

    foreach my $file (@files) {

        unlink $file or warn "Cannot remove $file: $!\n";

    }

    $ENV{SIEBEL_SRVRMGR_DEBUG} = undef;

}

1;
