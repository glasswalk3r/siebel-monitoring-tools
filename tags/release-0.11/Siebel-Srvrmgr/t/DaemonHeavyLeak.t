package My::Devel::Gladiator;

use Scalar::Util qw(weaken);
use Cwd;
use File::Spec;

sub new {

    my $class = shift;

    my $file = File::Spec->catfile( getcwd(), 'gladiator_output.txt' );

    open( my $out, '>', $file ) or die "Cannot create $file: $!";

    my $self = { counting => {}, out_h => $out };

    return bless $self, $class;

}

sub DESTROY {

    my $self = shift;

    close( $self->{out_h} ) or die $!;

}

sub show_accounting {

    my $self = shift;
    my $out  = $self->{out_h};

    foreach my $key ( sort( keys( %{ $self->{counting} } ) ) ) {

        print $out $key, ' -> ', join( '|', @{ $self->{counting}->{$key} } ),
          "\n"
          if (
            $self->{counting}->{$key}->[1] > $self->{counting}->{$key}->[0] );

    }

}

sub count_leaks {

    my $self = shift;

    my $total = 0;

    foreach my $key ( keys( %{ $self->{counting} } ) ) {

        my $last = $#{ $self->{counting}->{$key} };

        $total++
          if ( $self->{counting}->{$key}->[$last] >
            $self->{counting}->{$key}->[ $last - 1 ] );

    }

    return $total;

}

sub increment_count {

    my $self    = shift;
    my $current = shift;

    weaken($current);

    foreach my $key ( keys( %{$current} ) ) {

        if ( exists( $self->{counting}->{$key} ) ) {

            push( @{ $self->{counting}->{$key} }, $current->{$key} );

        }
        else {

            $self->{counting}->{$key} = [ $current->{$key} ];

        }

    }

}

package main;

use warnings;
use strict;
use Test::Most;
use Siebel::Srvrmgr::Daemon::Heavy;
use Cwd;
use File::Spec;
use Scalar::Util qw(weaken);

my $repeat = 3;

plan tests => $repeat;

SKIP: {

    skip( 'Devel:Gladiator not installed on this system', $repeat )
      unless do {
        eval "use Devel::Gladiator qw(arena_ref_counts)";
        $@ ? 0 : 1;
      };

    skip 'Not a developer machine', $repeat
      unless ( $ENV{SIEBEL_SRVRMGR_DEVEL} );

    my $daemon = Siebel::Srvrmgr::Daemon::Heavy->new(
        {
            gateway     => 'whatever',
            enterprise  => 'whatever',
            user        => 'whatever',
            password    => 'whatever',
            server      => 'whatever',
            bin         => File::Spec->catfile( getcwd(), 'srvrmgr-mock.pl' ),
            use_perl    => 1,
            is_infinite => 0,
            timeout     => 0,
            commands    => [
                Siebel::Srvrmgr::Daemon::Command->new(
                    command => 'list comp',
                    action  => 'Dummy'
                )
            ]
        }
    );

    my $gladiator = My::Devel::Gladiator->new();

    for ( 1 .. $repeat ) {

        $daemon->run();

        $gladiator->increment_count( arena_ref_counts() );
        is( $gladiator->count_leaks(), 0, 'gladiator gots zero leaks' );

    }

    $gladiator->show_accounting();

}
