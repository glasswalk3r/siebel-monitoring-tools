use warnings;
use strict;
use File::Spec;
use Siebel::Srvrmgr::ListParser;
use Cwd;
use Test::More;

my @files = (
    [
        File::Spec->catfile(
            getcwd(), 't', 'output', 'fixed', '8.1.1.5_21229.txt'
        ),
        '8.1.1.5',
        21229, 4
    ],
    [
        File::Spec->catfile(
            getcwd(), 't', 'output', 'fixed', '8.0.0.2_20412.txt'
        ),
        '8.0.0.2',
        20412, 1
    ],
    [
        File::Spec->catfile(
            getcwd(), 't', 'output', 'delimited', '8.0.0.2_20412.txt'
        ),
        '8.0.0.2',
        20412, 1
    ]
);

my @expected = (
    'Siebel::Srvrmgr::ListParser::Output::LoadPreferences',
    'Siebel::Srvrmgr::ListParser::Output::Tabular::ListComp',
    'Siebel::Srvrmgr::ListParser::Output::Tabular::ListCompTypes',
    'Siebel::Srvrmgr::ListParser::Output::Tabular::ListParams',
    'Siebel::Srvrmgr::ListParser::Output::Tabular::ListParams',
    'Siebel::Srvrmgr::ListParser::Output::Tabular::ListCompDef',
    'Siebel::Srvrmgr::ListParser::Output::Tabular::ListCompDef',
    'Siebel::Srvrmgr::ListParser::Output::Tabular::ListTasks',
    'Siebel::Srvrmgr::ListParser::Output::Tabular::ListTasks',
    'Siebel::Srvrmgr::ListParser::Output::Tabular::ListServers'
);

plan tests => ( ( scalar(@expected) + 6 ) * scalar(@files) );

foreach my $item (@files) {

    note( 'Testing file ' . $item->[0] );

    my $data_ref = read_data( $item->[0] );

    my $parser;

    if ( $item->[0] =~ /delimited/ ) {

        $parser =
          Siebel::Srvrmgr::ListParser->new( { field_delimiter => '|' } );

    }
    else {

        $parser = Siebel::Srvrmgr::ListParser->new();

    }

    $parser->parse($data_ref);

    my $res = $parser->get_parsed_tree();

    is( scalar( @{$res} ),
        scalar(@expected),
        'the expected number of parsed objects is returned' );

    isa_ok( $parser->get_enterprise(),
        'Siebel::Srvrmgr::ListParser::Output::Enterprise' );
    is( $parser->get_enterprise()->get_version(),
        $item->[1], 'enterprise attribute has the correct version' );
    is( $parser->get_enterprise()->get_patch(),
        $item->[2], 'enterprise attribute has the correct patch number' );
    is( $parser->get_enterprise()->get_total_servers(),
        $item->[3],
        'enterprise attribute returns the correct number of servers' );
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

}

sub read_data {

    my $path = shift;

    open( my $in, '<', $path ) or die "Cannot read $path: $!\n";

    my @data;

    while (<$in>) {

        s/\015?\012$/\012/o;    #normalize EOL
        chomp();
        push( @data, $_ );

    }

    close($in);

    return \@data;

}
