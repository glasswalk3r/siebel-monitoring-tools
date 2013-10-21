package Nagios::Plugin::Siebel::Srvrmgr::Daemon::Cache;

use Moose;
use namespace::autoclean;
use CHI;
use Nagios::Plugin::Siebel::Srvrmgr::Exception::CacheFailure;
use Scalar::Util qw(weaken);

extends 'Nagios::Plugin::Siebel::Srvrmgr::Daemon';

has 'cache_expires' => (
    is      => 'rw',
    isa     => 'Int',
    reader  => 'get_cache_expires',
    writer  => 'set_cache_expires',
    default => 120
);
has 'cache' => (
    is     => 'ro',
    isa    => 'Ref',
    reader => 'get_cache',
    writer => '_set_cache'
);

sub BUILD {

    my $self = shift;

    super();

    $self->_set_cache(
        CHI->new(
            namespace  => __PACKAGE__,
            driver     => 'Memory',
            expires_in => $self->get_cache_expires(),
            global     => 1
        )
    );

}

override 'check_comp' => sub {

    my $self        = shift;
    my $server_name = shift;
    my $comp_alias  = shift;

    my $comp = $self->_validate_alias( $server_name, $comp_alias );

    unless ( $self->get_cache()->is_valid($comp_alias) ) {

        $self->get_daemon()->run();
        $self->get_daemon()->shift_commands();
        $self->get_comp_status($server_name, $comp);
        $self->_feed_cache( $server_name, $comp );

    }
    else {

        my $status = $self->get_cache()->get($comp_alias);
        $comp->set_isOK($status);

    }

    return $comp;

};

# feed all returned data and return the specific component result
sub _feed_cache {

    my $self         = shift;
    my $server_name  = shift;
    my $srvrmgr_data = $self->get_stash()->shift_stash();

    foreach my $comp_alias ( keys( %{ $srvrmgr_data->{$server_name} } ) ) {

        die Nagios::Plugin::Siebel::Srvrmgr::Exception::CacheFailure->new()
          unless ( $self->get_cache()
            ->set( $comp_alias, $srvrmgr_data->{$server_name}->{$comp_alias} )
          );

    }

}

__PACKAGE__->meta->make_immutable();

1;
