use strict;
use warnings;
use Test::More tests => 2;
use Config;
use File::Spec;
use File::Temp;

BEGIN { use_ok('Siebel::Srvrmgr::Nagios') }

my ( $fh, $filename ) = tempfile( 'output-XXXX', UNLINK => 1 );
my $config = File::Spec->catfile( 't', 'test.xml' );
my @args = (
    File::Spec->catfile( $Config{bin}, 'perl' ),
    'comp_mon.pl', '-w', '1', '-c', '3', '-f', $config, '>', $filename
);
system(@args);

is( ( $? >> 8 ), 2, 'comp_mon.pl returns a CRITICAL' )
  or diag( check_exec($?) );

TODO: {

    local $TODO = "must redirect output to a file and check the results";

    my @data = <$fh>;
    close($fh);

    is( @data, 'WARNING', 'got the expected output' );

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

