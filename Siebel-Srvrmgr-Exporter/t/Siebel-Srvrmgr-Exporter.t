use strict;
use warnings;
use Test::More tests => 5;
use Digest::MD5;
use Config;
use File::Spec;
use Cwd;

BEGIN { use_ok('Siebel::Srvrmgr::Exporter') }

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

    $expected_digest = 'a64debe4934a962da1310048637e3a9e';

}

my $filename = 'test.txt';

# srvrmgr-mock.pl ignores all parameters

my $dummy = 'foobar';
my $mock = File::Spec->catfile( $Config{sitebin}, 'srvrmgr-mock.pl' );

unless ( -e $mock ) {

    note(
"Could not locate srvrmgr-mock.pl in Config sitebin ($Config{sitebin}). Hoping that the script is available on the current PATH"
    );

    my @paths = split( ':', $ENV{PATH} );
    foreach my $path (@paths) {

        my $full_path = File::Spec->catfile( $path, 'srvrmgr-mock.pl' );
        if ( -e $full_path ) {
            $mock = $full_path;
            last;
        }
    }
    note("Found srvrmgr-mock.pl ('$mock')");
}
ok( -x $mock, 'srvrmgr-mock.pl is executable' );
note('Fetching values, this can take some seconds');
my $exports = File::Spec->catfile( getcwd(), 'bin', 'export_comps.pl' );
ok( -e $exports, 'export_comps.pl exists' );
ok( -r $exports, 'export_comps.pl is readable' );
my $path_to_perl = $Config{perlpath};
note("Trying with with '$path_to_perl', '$exports', '$mock'");
my $ret = system( $path_to_perl, '-Ilib', $exports, '-s', $dummy,
    '-g',   $dummy,   '-e',   $dummy, '-u',
    $dummy, '-p',     $dummy, '-b',   $mock,
    '-r',   'SRProc', '-x',   '-o',   $filename,
    '-q'
);

unless ( $ret == 0 ) {

    fail("Failed to execute export_comps.pl: $!");

}
else {

    open( my $fh, '<', $filename ) or die "Can't open '$filename': $!";
    binmode($fh);
    is( Digest::MD5->new->addfile($fh)->hexdigest(),
        $expected_digest, 'got expected output from srvrmgr-mock' );
    close($fh);
    unlink($filename) or diag("Cannot remove $filename: $!");

}
