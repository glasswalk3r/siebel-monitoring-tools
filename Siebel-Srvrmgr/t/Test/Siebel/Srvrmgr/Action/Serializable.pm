package Test::Siebel::Srvrmgr::Action::Serializable;

use base qw(Test::Siebel::Srvrmgr Test::Siebel::Srvrmgr::Action);
use Test::Most;

sub get_dump {

    my $test = shift;

    my $name = __PACKAGE__;
    $name =~ s/\:{2}/_/g;

    return $name . '_storable';

}

sub get_my_data {

    my $test = shift;

# :WORKAROUND:07/06/2013 16:02:18:: the superclass will get a reference of Test::Action::Serializable, but we have no DATA section here
# so it's better to return the parents'
    if ( ref($test) eq 'Test::Siebel::Srvrmgr::Action::Serializable' ) {

        return Test::Siebel::Srvrmgr::Action::get_my_data;    # abstract method

    }

    return $test->SUPER::get_my_data()
      ;    # due to multiple inheritance, method from Test::ReadMyself

}

sub startup : Tests(startup => +1) {

    my $test = shift;

    $test->SUPER::startup();

    ok(
        $test->{action} = $test->class()->new(
            {
                parser => Siebel::Srvrmgr::ListParser->new(),
                params => [ $test->get_dump() ]
            }
        ),
        'the constructor should succeed'
    );

}

sub class_methods : Tests(+3) {

    my $test = shift;

    $test->SUPER::class_methods();

# :WORKAROUND:07/06/2013 16:30:11:: this will invoke methods that the parent uses class() returned reference does not supports
  SKIP: {

        skip 'parent class will not be able to execute those methods', 3
          if ( $test->class() eq 'Siebel::Srvrmgr::Daemon::Action' );

        can_ok( $test->{action}, qw(get_dump_file set_dump_file) );

        is( $test->{action}->get_dump_file(),
            $test->get_dump(), 'get_dump_file returns the correct string' );

        ok( $test->{action}->set_dump_file( $test->get_dump ),
            'set_dump_file works' );

    }

}

sub DESTROY {

    my $test = shift;

# :WORKAROUND:07/06/2013 16:39:28:: this class does not generate any file, just the subclasses
    unless ( ref($test) eq 'Test::Siebel::Srvrmgr::Action::Serializable' ) {

        unlink( $test->get_dump() )
          or warn 'Cannot remove ' . $test->get_dump() . ': ' . $!;

    }

}

sub recover_me : Test {

    my $test = shift;

    my $class = 'Test::Siebel::Srvrmgr::Action::Serializable';

  SKIP: {

        skip 'Cannot test myself and expect to pass this test', 1
          if ( ref($test) eq 'Test::Siebel::Srvrmgr::Action::Serializable' );

# :WARNING   :07/06/2013 16:58:13:: this tests does not verifies the Siebel::Srvrmgr API, but it will help to
# detect that a subclass of Serializable was not finished correctly
        ok(
            ( ( ( $test->isa($class) ) and ( ref($test) ne $class ) ) ? 1 : 0 ),
            'method recover_me needs to be overrided by subclasses of '
              . $class
        );

    }

}

1;
