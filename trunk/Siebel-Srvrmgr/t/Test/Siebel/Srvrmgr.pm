package Test::Siebel::Srvrmgr;

use Test::More;
use File::Spec;
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

sub get_output_file {

    my $test = shift;

    return $test->{output_file};

}

sub get_my_data {

    my $test = shift;

    open( my $in, '<', $test->get_output_file() )
      or die 'cannot read ' . $test->get_output_file() . ': ' . $!;

    my @data;

    while (<$in>) {

        # input text files for testing are expected to have UNIX EOL character
        s/\012$//;
        push( @data, $_ );

    }

    close($in);

    $test->{data} = \@data;
    return $test->{data};

}

1;
