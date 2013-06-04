package Test::Daemon::RunOK;

use Test::More;
use Cwd;
use base 'Test::Daemon';

sub class_exec_processing : Test(+1) {

    my $test  = shift;
    my $class = $test->class;

    $SIG{INT} = \&clean_up;

    ok( $test->{daemon}->run(), 'run method executes successfuly' );

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
