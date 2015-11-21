use strict;
use warnings;
use Test::More tests => 2;
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
die "Cannot find srvrmgr-mock.pl for execution"
  unless ( -e $mock );

note('Fetching values, this can take some seconds');
my $exports = File::Spec->catfile( getcwd(), 'bin', 'export_comps.pl' );
die "Cannot find export_comps.pl for execution"
  unless ( -e $exports );

system(
    'perl', '-Ilib', $exports,
    '-s', $dummy, '-g', $dummy,
    '-e', $dummy, '-u', $dummy,
    '-p', $dummy, '-b',
    $mock, 
    '-r',      'SRProc', '-x', '-o',
    $filename, '-q'
  ) == 0
  or die "failed to execute export_comps.pl: $!\n";

open( my $fh, '<', $filename ) or die "Can't open '$filename': $!";
binmode($fh);
is( Digest::MD5->new->addfile($fh)->hexdigest(),
    $expected_digest, 'got expected output from srvrmgr-mock' );

close($fh);

unlink($filename) or die "Cannot remove $filename: $!\n";
