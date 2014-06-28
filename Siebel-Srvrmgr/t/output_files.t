use warnings;
use strict;
use File::Spec;
use Siebel::Srvrmgr::ListParser;
use Cwd;
use Test::More;

# for regression tests with older Siebel releases, which we don't have the output
# from all the supported commands
my @old_expected = (
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
    'Siebel::Srvrmgr::ListParser::Output::Tabular::ListServers',
    'Siebel::Srvrmgr::ListParser::Output::Tabular::ListSessions',
    'Siebel::Srvrmgr::ListParser::Output::Tabular::ListSessions',
    'Siebel::Srvrmgr::ListParser::Output::Tabular::ListSessions',
);

# 0 - filename
# 1 - version
# 2 - patch version
# 3 - number of available servers
# 4 - array ref of expected output
my @files = (
    [
        File::Spec->catfile(
            getcwd(), 't', 'output', 'fixed', '8.1.1.5_21229.txt'
        ),
        '8.1.1.5',
        21229, 4,
        \@old_expected
    ],
    [
        File::Spec->catfile(
            getcwd(), 't', 'output', 'fixed', '8.0.0.2_20412.txt'
        ),
        '8.0.0.2',
        20412, 1,
        \@old_expected
    ],
    [
        File::Spec->catfile(
            getcwd(), 't', 'output', 'delimited', '8.0.0.2_20412.txt'
        ),
        '8.0.0.2',
        20412, 1,
        \@old_expected
    ],
    [
        File::Spec->catfile(
            getcwd(), 't', 'output', 'delimited', '8.1.1.7_21238.txt'
        ),
        '8.1.1.7',
        21238, 3,
        \@expected
    ],
    [
        File::Spec->catfile(
            getcwd(), 't', 'output', 'fixed', '8.1.1.7_21238.txt'
        ),
        '8.1.1.7',
        21238, 3,
        \@expected
    ]
);

my $tests = 0;

# calculating the number of tests to be executed
foreach my $item (@files) {

    $tests += scalar( @{ $item->[4] } ) + 6;

}

plan tests => $tests;

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

    my $got    = scalar( @{$res} );
    my $expect = scalar( @{ $item->[4] } );

    is( $got, $expect, 'the expected number of parsed objects is returned' );

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

        skip 'number of parsed objects must be equal to the expected', $expect
          unless ( $got == $expect );

        for ( my $i = 0 ; $i < $expect ; $i++ ) {

            is(
                ref( $res->[$i] ),
                $item->[4]->[$i],
                'the object returned is a ' . $item->[4]->[$i]
            );

        }

    }

}

sub read_data {

    my $path = shift;

    open( my $in, '<', $path ) or die "Cannot read $path: $!\n";

    my @data;

    while (<$in>) {

        s/\015?\012$/\012/o;    #setting EOL to a sane value
        chomp();
        push( @data, $_ );

    }

    close($in);

    return \@data;

}
