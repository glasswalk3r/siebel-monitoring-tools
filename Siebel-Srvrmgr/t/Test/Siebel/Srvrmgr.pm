package Test::Siebel::Srvrmgr;

use Test::More;
use base qw(Test::Class Class::Data::Inheritable);

BEGIN {
    __PACKAGE__->mk_classdata('class');
}

sub startup : Test( startup => 1 ) {

    my $test = shift;

# removes the Test:: from the child class package name, so it is expected that the resulting package name exists in @INC
    ( my $class = ref $test ) =~ s/^Test:://;
    return 1, "$class loaded" if $class eq __PACKAGE__;

    use_ok $class or die;
    $test->class($class);

}

sub get_my_data {

    my $test = shift;

    if ( exists( $test->{data} ) ) {

        return $test->{data};

    }
    else {

        my $handle = ref($test) . '::DATA';
        my @data;

        while (<$handle>) {
 # :WORKAROUND:12/08/2013 12:27:24:: new implementation of Daemon removes new lines characters from srvrmgr output
            chomp();
            push( @data, $_ );

        }

        close($handle);

        if (@data) {

			$test->{data} = \@data;
		    return $test->{data};

        }

# :WORKAROUND:25/06/2013 16:51:19:: to avoid multiple inheritance, this will support subclasses that needs dummy data to be returned
# as Test::Siebel::Srvrmgr::Action does
        else {

            return [qw(foo bar something)];

        }

    }

}

1;
