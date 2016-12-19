use strict;
use warnings;
use Test::More;
use Digest::MD5;
use Config;
use File::Spec;
use Cwd;
use Capture::Tiny 0.36 'capture';
use Test::TempDir::Tiny 0.016;
use File::Copy;

require_ok('Siebel::Srvrmgr::Exporter');

# calculated with:
# -for Linux
# perl -MDigest::MD5 -e '$filename = shift; open($fh, "<", $filename) or die $!; binmode($fh); print Digest::MD5->new->addfile($fh)->hexdigest, "\n"' test.txt
# - for Windows
#
my $expected_digest;

# the differences below are due the line end character differences
if ( $Config{osname} eq 'MSWin32' ) {
    $expected_digest = 'cafb36f3bf6c2387bc4b9ffab3337ea8';
}
else {    # else is for UNIX-line OS
    $expected_digest = '3dc2528e294874c95d58d07192b7d7a8';
}

my $temp_dir = tempdir();
my $filename = File::Spec->catfile( $temp_dir, 'test.txt' );
copy( File::Spec->catfile( 't', 'output', 'offline.txt' ), $temp_dir );
my $offline = File::Spec->catfile( $temp_dir, 'offline.txt' );
my $exports = File::Spec->catfile( 'blib', 'script', 'export_comps.pl' );
ok( -e $exports, 'export_comps.pl exists' );
ok( -r $exports, 'export_comps.pl is readable' );
ok( -x $exports, 'export_comps.pl is readable' );
my $path_to_perl = $Config{perlpath};

my ( $stdout, $stderr, $exit ) = capture {
    system( $path_to_perl, '-Ilib', $exports, '--output',
        $filename, '--quiet',     '--exclude', '--offline',
        $offline,  '--delimiter', '|', '--regex', 'SRProc'
    );
};
note('STDOUT: '. $stdout);
note('STDERR: '. $stderr);
is( $exit, 0, "successfully executed $exports" )
  or diag("Failed to execute $exports: $stderr");
open( my $fh, '<', $filename ) or diag("Can't open '$filename': $!");
binmode($fh);
is( Digest::MD5->new->addfile($fh)->hexdigest(),
    $expected_digest, 'got expected output' );
close($fh);
unlink($filename) or diag("Cannot remove $filename: $!");
done_testing;

