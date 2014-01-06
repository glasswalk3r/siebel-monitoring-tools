package Test::Siebel::Srvrmgr::ListParser;

use Test::Most;
use Test::Moose 'has_attribute_ok';
use parent 'Test::Siebel::Srvrmgr';

sub class_attributes : Tests(8) {

    my $test = shift;

    my @attribs = (
        'parsed_tree', 'has_tree', 'last_command', 'is_cmd_changed',
        'buffer',      'enterprise'
    );

    foreach my $attrib (@attribs) {

        has_attribute_ok( $test->{parser}, $attrib );

    }

}

sub _constructor : Test(2) {

    my $test = shift;

    ok(
        $test->{parser} = $test->class()->new(),
        'it is possible to create an instance'
    );

    isa_ok( $test->{parser}, $test->class(),
        'the instance is from the expected class' );

}

sub class_methods : Tests(11) {

    my $test  = shift;
    my $class = $test->class;

    #extended method tests
    can_ok(
        $class,
        (
            'get_parsed_tree', 'get_last_command',
            'is_cmd_changed',  'set_last_command',
            'set_buffer',      'clear_buffer',
            'count_parsed',    'clear_parsed_tree',
            'set_parsed_tree', 'append_output',
            'parse',           'get_buffer',
            'new',             'get_enterprise',
            '_set_enterprise'
        )
    );

    is(
        ref( $test->{parser}->get_buffer() ),
        ref( [] ),
        'get_buffer returns an array reference'
    );

    # :WORKAROUND:29-10-2013:arfreitas: providing data to the last two tests
    my @backup;

    # just the list comp command and it's output
    for ( my $i = 26 ; $i <= 59 ; $i++ ) {

        push( @backup, $test->get_my_data()->[$i] );

    }

    $backup[0] =~ s/^srvrmgr\:SUsrvr\>/srvrmgr:S%srvr>/;

    ok( $test->{parser}->parse( $test->get_my_data() ), 'parse method works' );

    isa_ok( $test->{parser}->get_enterprise(),
        'Siebel::Srvrmgr::ListParser::Output::Greetings' );

    is(
        scalar( @{ $test->{parser}->get_buffer() } ),
        scalar( @{ [] } ),
        'calling parse method automatically resets the buffer'
    );

    ok( $test->{parser}->clear_buffer(), 'clear_buffer method works' );

    ok( $test->{parser}->has_tree(), 'the parser has a parsed tree' );

    my $last_cmd = 'list comp def SRProc';

    is( $test->{parser}->get_last_command(),
        $last_cmd, "get_last_command method returns $last_cmd" );

    my $total_itens = 6;

    is( $test->{parser}->count_parsed(),
        $total_itens, "count_parsed method returns $total_itens" );

    dies_ok(
        sub { $test->{parser}->parse( \@backup ) },
        'parse() dies if cannot find the prompt'
    );
    like(
        $@,
        qr/could\snot\sfind\sthe\scommand\sprompt/,
        'get the correct error message'
    );

}

1;
