package Test::Siebel::Srvrmgr;

use Test::More;
use File::Spec;
use String::BOM qw(string_has_bom strip_bom_from_string);
use parent qw(Test::Class Class::Data::Inheritable);
use Carp;

BEGIN {
    __PACKAGE__->mk_classdata('class');
}

sub new {

    my $class      = shift;
    my $params_ref = shift;
    my $self;

    if ( defined($params_ref) ) { # ones that use get_my_data

        confess "must receive an hash reference as parameter"
          unless ( ref($params_ref) eq 'HASH' );

        $params_ref->{output_file} =
          File::Spec->catfile( @{ $params_ref->{output_file} } );

        $self = $class->SUPER::new( %{$params_ref} );

    }
    else {

        $self = $class->SUPER::new();

    }

    return $self;

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

    my $file = $test->get_output_file();

    confess "Don't have a defined file to read!" unless ( defined($file) );

    open( my $in, '<', $file )
      or die "cannot read $file: $!";

    my @data;

    while (<$in>) {

        # input text files for testing are expected to have UNIX EOL character
        s/\012$//;
        push( @data, $_ );

    }

    close($in);

    if ( string_has_bom( $data[0] ) ) {

        $data[0] = strip_bom_from_string( $data[0] );

    }

    return \@data;

}

1;
