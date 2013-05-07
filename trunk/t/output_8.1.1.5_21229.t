use warnings;
use strict;
use File::Spec;
use Siebel::Srvrmgr::ListParser;
use Cwd;
use Test::More tests => 11;

my $output_filename = '8.1.1.5_21229.txt';

my $path = File::Spec->catfile( getcwd(), 't', 'output', $output_filename );

open( my $in, '<', $path ) or die "Cannot read $path: $!\n";

my @data;

while (<$in>) {

    s/\r\n$//;
    s/\n$//;
    push( @data, $_ );

}

close($in);

my $parser = Siebel::Srvrmgr::ListParser->new();

$parser->parse( \@data );

my $res = $parser->get_parsed_tree();

my @expected = (
    'Siebel::Srvrmgr::ListParser::Output::Greetings',
    'Siebel::Srvrmgr::ListParser::Output::LoadPreferences',
    'Siebel::Srvrmgr::ListParser::Output::ListComp',
    'Siebel::Srvrmgr::ListParser::Output::ListCompTypes',
    'Siebel::Srvrmgr::ListParser::Output::ListParams',
    'Siebel::Srvrmgr::ListParser::Output::ListParams',
    'Siebel::Srvrmgr::ListParser::Output::ListCompDef',
    'Siebel::Srvrmgr::ListParser::Output::ListTasks',
    'Siebel::Srvrmgr::ListParser::Output::ListTasks',
    'Siebel::Srvrmgr::ListParser::Output::ListServers'
);

is( scalar( @{$res} ),
    scalar(@expected), 'the expected number of parsed objects is returned' );

SKIP: {

    skip 'number of parsed objects must be equal to the expected', 9
      unless ( ( scalar( @{$res} ) ) == ( scalar(@expected) ) );

    for ( my $i = 0 ; $i < scalar(@expected) ; $i++ ) {

        is( ref( $res->[$i] ),
            $expected[$i], "the object returned is a $expected[$i]" );

    }

}
