package Test::Siebel::Srvrmgr::ListParser::Output::ListComp::Server;

use Test::Most;
use Test::Moose qw(has_attribute_ok);
use parent 'Test::Siebel::Srvrmgr';
use Siebel::Srvrmgr::ListParser::Output::Tabular::ListComp;

sub _constructor : Tests(+2) {

    my $test = shift;

    #must parse the output
    my $list_comp = Siebel::Srvrmgr::ListParser::Output::Tabular::ListComp->new(
        {
            data_type => 'list_comp',
            raw_data  => $test->get_my_data(),
            cmd_line  => 'list comp'
        }
    );

    $test->{server} = $list_comp->get_server('foobar');

    ok( $test->{server}, 'the constructor should succeed' );
    isa_ok( $test->{server}, $test->class() );

}

# :TODO:11-01-2014:: refactor the method below because Tabular does the same (maybe a Role?)
sub get_my_data {

    my $test = shift;

    my $data_ref = $test->SUPER::get_my_data();

    shift( @{$data_ref} );    #command
    shift( @{$data_ref} );    #new line

    return $data_ref;

}

sub class_methods : Tests(5) {

    my $test = shift;

    can_ok( $test->{server},
        qw(new get_data get_name load store get_comps get_comp get_comp_data) );

    is( $test->{server}->get_name(),
        'foobar', 'get_name returns the correct value' );

    isa_ok(
        $test->{server}->get_comp('ClientAdmin'),
        'Siebel::Srvrmgr::ListParser::Output::ListComp::Comp',
        'get_comp returns a Comp object'
    );

    isa_ok( $test->{server}->get_comps(),
        'ARRAY', 'get_comps returns an array reference' );

    isa_ok( $test->{server}->get_comp_data('EIM'),
        'HASH', 'get_comp_data returns an hash reference' );

}

sub class_attributes : Tests(no_plan) {

    my $test = shift;

    my @attribs = qw(name data comp_attribs);
    $test->num_tests( scalar(@attribs) );

    foreach my $attrib (@attribs) {

        has_attribute_ok( $test->{server}, $attrib );

    }

}

1;

