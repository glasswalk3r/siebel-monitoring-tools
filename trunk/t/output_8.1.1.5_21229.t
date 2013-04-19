use warnings;
use strict;
use File::Spec;
use Siebel::Srvrmgr::ListParser;

my $output_filename = '8.1.1.5_21229.txt';

my $path = File::Spec->catfile( 'output', $output_filename );

open( my $in, '<', $path ) or die "Cannot read $path: $!\n";

my @data = <$in>;

close($in);

my $parser = Siebel::Srvrmgr::ListParser->new();

$parser->parse(\@data);

use Data::Dumper;

print Dumper($parser->get_parsed_tree());
