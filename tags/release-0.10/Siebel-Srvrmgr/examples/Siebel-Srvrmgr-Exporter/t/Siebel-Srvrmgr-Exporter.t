use strict;
use warnings;
use Test::More tests => 2;
use Digest::MD5;
use Config;
use File::Spec;

BEGIN { use_ok('Siebel::Srvrmgr::Exporter') }

# calculated with
# perl -M Digest::MD5 -e "$filename = shift; open (my $fh, '<', $filename) or die \"Can't open $filename: $!\"; binmode ($fh); print Digest::MD5->new->addfile($fh)->hexdigest, \"\n\"";
my $expected_digest;

# the differences below are due the line end character differences
if ( $Config{osname} eq 'MSWin32' ) {

    $expected_digest = 'e1d662b1be600d49af4cf92d40cd7fe0';

}
else { # else is for UNIX-line OS

    $expected_digest = '652aef6a89329e14c56fc6d33e6739f4';

}

my $filename = 'test.txt';

# srvrmgr-mock.pl ignores all parameters
my $dummy = 'foobar';

system(
    'perl', '-I',   '.\lib', 'export_comps.pl',
    '-s',   $dummy, '-g',    $dummy,
    '-e',   $dummy, '-u',    $dummy,
    '-p',   $dummy, '-b',
    File::Spec->catfile( $Config{sitebin}, 'srvrmgr-mock.pl' ),
    '-r',      'SRProc', '-x', '-o',
    $filename, '-q'
  ) == 0
  or die "failed to execute export_comps.pl: $!\n";

open( my $fh, '<', $filename ) or die "Can't open '$filename': $!";
binmode($fh);
is(
    Digest::MD5->new->addfile($fh)->hexdigest(),
    $expected_digest,
    'can get expected output from srvrmgr-mock'
);

close($fh);

unlink($filename) or die "Cannot remove $filename: $!\n";
