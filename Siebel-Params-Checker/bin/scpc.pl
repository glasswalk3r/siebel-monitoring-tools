use warnings;
use strict;
use Getopt::Std;
use Siebel::Params::Checker;
use File::HomeDir 1.00;
use File::Spec;

$Getopt::Std::STANDARD_HELP_VERSION = 2;

sub HELP_MESSAGE {

    my $option = shift;

    if ( ( defined($option) ) and ( ref($option) eq '' ) ) {

        print "'-$option' parameter cannot be null\n";

    }

    print <<BLOCK;

scpc - version

This program will connect to a Siebel server, check desired components parameters and print all information to STDOUT as a table for comparison.

The parameters available are:

	-r: required parameter of the regular expression to match component alias to export as parameter (case sensitive).
    -c: optional parameter to the complete path to the configuration file (defaults to .scpc.cfg in the user home directory).
        See the Pod of Siebel::Params::Checker for details on the configuration file.

The parameters below are optional:

	-h: prints this help message and exits

BLOCK

    exit(0);

}

our %opts;

getopts( 'r:c:h', \%opts );

HELP_MESSAGE() if ( exists( $opts{h} ) );

foreach my $option (qw(r)) {

    HELP_MESSAGE($option) unless ( defined( $opts{$option} ) );

}

my $cfg_file;
my $default = File::Spec->catfile( File::HomeDir->my_home(), '.scpc.cfg' );

if ( exists( $opts{c} ) ) {

    if ( -r $opts{c} ) {
        $cfg_file = $opts{c};
    }
    else {
        die "file $opts{c} does not exist or is not readable";
    }

}
elsif ( -e $default ) {
    $cfg_file = $default;
}
else {
    die
"No default configuration file available, create it or specify one with -c option";
}

my $comp_regex = qr/$opts{r}/;
my $data_ref = recover_info( $cfg_file, $comp_regex );
use Data::Dumper;
print Dumper($data_ref);
