package Test::Siebel::Srvrmgr::Daemon::Action;

use Test::Most;
use Siebel::Srvrmgr::ListParser;
use Test::Moose 'has_attribute_ok';
use Cwd;
use base 'Test::Siebel::Srvrmgr';

sub before : Tests(setup) {

    my $test = shift;

	$test->{parser} = Siebel::Srvrmgr::ListParser->new();

    # :TODO      :08/07/2013 12:50:51:: defined methods instead using references
    # keeps the subclass of Siebel::Srvrmgr::Daemon as an attribute
    $test->{action} = $test->class()->new(
        {
            parser => $test->{parser}, 
            params => ['foobar']
        }
    );

}

sub constructor : Tests(2) {

    my $test = shift;

    ok( $test->{action}, 'the constructor works' );
    isa_ok( $test->{action}, $test->class() );

}

sub class_attributes : Tests(2) {

    my $test = shift;

    foreach my $attrib (qw(parser params)) {

        has_attribute_ok( $test->{action}, $attrib );

    }

}

sub class_methods : Tests(6) {

    my $test = shift;

    my $parser_class = 'Siebel::Srvrmgr::ListParser';

    isa_ok( $test->{action}->get_parser(),
        $parser_class, "get_parser returns a $parser_class instance" );

    can_ok( $test->{action},
        qw(new get_params get_parser do do_parsed) );

  SKIP: {

        skip 'superclass does not returns data with get_my_data', 1
          if ( ref( $test->{action} ) eq 'Siebel::Srvrmgr::Daemon::Action' );

        ok(
            $test->{action}->do( $test->get_my_data() ),
            'do method works with get_my_data()'
        );

    }

  SKIP: {

        skip 'tests just for superclass', 2
          if (
            ref( $test->{action} ) ne 'Siebel::Srvrmgr::Daemon::Action' );

        dies_ok( sub { $test->{action}->do('simple string') },
            'do method raises an exception with wrong type of parameter' );

        dies_ok( sub { $test->{action}->do_parsed() },
            'does_parsed of superclass causes an exception' );

    }

    ok( $test->{action}->get_params(), 'get_params works returns data' );

}

sub clean_up : Test(shutdown) {

    my $test = shift;

    # removes the dump files
    my $dir = getcwd();

    opendir( DIR, $dir ) or die "Cannot read $dir: $!\n";
    my @files = readdir(DIR);
    close(DIR);

# :TODO      :08/07/2013 12:50:22:: change for a proper interface instead hoping for data structure be the expected
    my $filename = '^' . ( @{ $test->{action}->get_params() } )[0];
    my $regex = qr/$filename/;

    foreach my $file (@files) {

        if ( $file =~ /$regex/ ) {

            unlink $file or warn "Cannot remove $file: $!\n";

        }

    }

}

1;
