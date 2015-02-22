package My::Devel::Gladiator;

use Scalar::Util qw(weaken);
use Cwd;
use File::Spec;

sub new {

    my $class = shift;

    my $self = { account => {} };

    return bless $self, $class;

}

sub show {

    my $self = shift;

    my %data;

    foreach my $key ( sort( keys( %{ $self->{account} } ) ) ) {

        my $last = scalar( @{ $self->{account}->{$key} } ) - 1;

        $data{$key} = $self->{account}->{$key}
          if ( $self->{account}->{$key}->[$last] >
            $self->{account}->{$key}->[ $last - 1 ] );

    }

    return \%data;

}

sub count_leaks {

    my $self = shift;

    my $total = 0;

    foreach my $key ( keys( %{ $self->{account} } ) ) {

        my $last = $#{ $self->{account}->{$key} };

        $total++
          if ( $self->{account}->{$key}->[$last] >
            $self->{account}->{$key}->[ $last - 1 ] );

    }

    return $total;

}

sub increment_count {

    my $self    = shift;
    my $current = shift;

    weaken($current);
    my $regex = qr/\:{2}/;

    foreach my $key ( keys( %{$current} ) ) {

        next unless ( $key =~ $regex );

        if ( exists( $self->{account}->{$key} ) ) {

            push( @{ $self->{account}->{$key} }, $current->{$key} );

        }
        else {

            $self->{account}->{$key} = [ $current->{$key} ];

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

    skip( 'Devel::Gladiator not installed on this system', $repeat )
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
        is( $gladiator->count_leaks(), 0, 'gladiator has zero leaks' )
          or explain( $gladiator->show );

    }

}
