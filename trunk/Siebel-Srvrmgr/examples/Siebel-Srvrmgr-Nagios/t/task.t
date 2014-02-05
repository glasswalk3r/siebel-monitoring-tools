use strict;
use warnings;
use Test::More tests => 2;
use File::Spec;
use Config;
BEGIN { use_ok('Siebel::Srvrmgr::Nagios') }

$SIG{INT} = \&clean_up;

my $config = File::Spec->catfile( 't', 'test.xml' );
my @args = (
    ( File::Spec->catfile( $Config{bin}, 'perl' ) ),
    'task_mon.pl', '-w', '1', '-c', '3', '-f', $config
);
system(@args);

is( ( $? >> 8 ), 2, 'task_mon.pl returns a CRITICAL' )
  or diag( check_exec($?) );

sub clean_up {

    unlink($config) or die "Could not remove $config: $!";

}

sub check_exec {

    my $error_code = shift;

    if ( $error_code == -1 ) {
        return "failed to execute: $!\n";
    }
    elsif ( $error_code & 127 ) {
        return sprintf(
            "child died with signal %d, %s coredump",
            (
                ( $error_code & 127 ),
                ( $error_code & 128 ) ? 'with' : 'without'
            )
        );
    }
    else {

        return sprintf "child exited with value %d\n", $? >> 8;

    }

}

