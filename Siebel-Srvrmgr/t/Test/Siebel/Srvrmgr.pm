package Test::Siebel::Srvrmgr;

use base qw(Test::Class);

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
