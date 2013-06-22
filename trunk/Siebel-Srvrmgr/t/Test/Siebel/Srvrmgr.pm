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

        my @data = <$handle>;
        close($handle);

        return $test->{data} = \@data;

    }

}

1;
