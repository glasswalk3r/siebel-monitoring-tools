use warnings;
use strict;
use File::Spec;
use Siebel::Srvrmgr::ListParser;
use Cwd;
use Test::More;
use Socket qw(:crlf);

my $output_filename = '8.1.1.5_21229.txt';

my $path = File::Spec->catfile( getcwd(), 't', 'output', $output_filename );

open( my $in, '<', $path ) or die "Cannot read $path: $!\n";

my @data;

{
	
	local $/ = LF;

	while (<$in>) {

		s/$CR?$LF/\n/;
		chomp();
		push( @data, $_ );

	}
		
}

close($in);

my $parser = Siebel::Srvrmgr::ListParser->new();

$parser->parse( \@data );

my $res = $parser->get_parsed_tree();

my @expected = (
    'Siebel::Srvrmgr::ListParser::Output::LoadPreferences',
    'Siebel::Srvrmgr::ListParser::Output::ListComp',
    'Siebel::Srvrmgr::ListParser::Output::ListCompTypes',
    'Siebel::Srvrmgr::ListParser::Output::ListParams',
    'Siebel::Srvrmgr::ListParser::Output::ListParams',
    'Siebel::Srvrmgr::ListParser::Output::ListCompDef',
    'Siebel::Srvrmgr::ListParser::Output::ListCompDef',
    'Siebel::Srvrmgr::ListParser::Output::ListTasks',
    'Siebel::Srvrmgr::ListParser::Output::ListTasks',
    'Siebel::Srvrmgr::ListParser::Output::ListServers'
);

# + the tests below
plan tests => ( scalar(@expected) + 7 );

is( scalar( @{$res} ),
    scalar(@expected), 'the expected number of parsed objects is returned' );

isa_ok( $parser->get_enterprise(),
    'Siebel::Srvrmgr::ListParser::Output::Greetings' );
is( $parser->get_enterprise()->get_version(),
    '8.1.1.5', 'enterprise attribute has the correct version' );
is( $parser->get_enterprise()->get_patch(),
    '21229', 'enterprise attribute has the correct patch number' );
is( $parser->get_enterprise()->get_patch(),
    '21229', 'enterprise attribute has the correct patch number' );
is( $parser->get_enterprise()->get_total_servers(),
    4, 'enterprise attribute returns the correct number of servers' );
is(
    $parser->get_enterprise()->get_total_servers(),
    $parser->get_enterprise()->get_total_conn(),
'enterprise attribute has the correct number of servers and connected servers'
);

SKIP: {

    skip 'number of parsed objects must be equal to the expected',
      scalar(@expected)
      unless ( ( scalar( @{$res} ) ) == ( scalar(@expected) ) );

    for ( my $i = 0 ; $i < scalar(@expected) ; $i++ ) {

        is( ref( $res->[$i] ),
            $expected[$i], "the object returned is a $expected[$i]" );

    }

}
