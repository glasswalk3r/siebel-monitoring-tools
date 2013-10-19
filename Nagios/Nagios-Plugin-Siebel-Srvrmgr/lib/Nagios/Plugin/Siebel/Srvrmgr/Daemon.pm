package Nagios::Plugin::Siebel::Srvrmgr::Daemon;

use Moose;
use Siebel::Srvrmgr::Daemon::Light;
use Siebel::Srvrmgr::Daemon::ActionStash;
use YAML::Syck;
use File::Spec;
use Nagios::Plugin::Siebel::Srvrmgr::Action::Check::Component;
use Nagios::Plugin::Siebel::Srvrmgr::Action::Check::Server;
use namespace::autoclean;
use Nagios::Plugin::Siebel::Srvrmgr::Exception::InvalidCompAlias;
use Nagios::Plugin::Siebel::Srvrmgr::Exception::InvalidCompConf;
use Nagios::Plugin::Siebel::Srvrmgr::Exception::InvalidServer;
use Nagios::Plugin::Siebel::Srvrmgr::Exception::NotFoundCompAlias;
use Nagios::Plugin::Siebel::Srvrmgr::Exception::InvalidSrvrmgrData;
use Nagios::Plugin::Siebel::Srvrmgr::Exception::CompNotEqual;
use Scalar::Util qw(weaken);

has 'config_file' =>
  ( is => 'ro', isa => 'Str', reader => 'get_config_file', required => 1 );
has 'daemon' => (
    is       => 'ro',
    isa      => 'Siebel::Srvrmgr::Daemon',
    reader   => 'get_daemon',
    writer   => '_set_daemon'
);
has 'stash' => (
    is     => 'ro',
    isa    => 'Siebel::Srvrmgr::Daemon::ActionStash',
    reader => 'get_stash',
    writer => '_set_stash'
);
has 'siebel_servers' => (
    is     => 'ro',
    isa    => 'HashRef[Nagios::Plugin::Siebel::Srvrmgr::Action::Check::Server]',
    reader => 'get_siebel_server',
    writer => '_set_siebel_server'
);
has use_perl =>
  ( isa => 'Bool', is => 'ro', reader => 'use_perl', default => 0 );

sub BUILD {

    my $self = shift;

# :WORKAROUND:13/06/2013 10:18:53:: the cfg may have multiple servers, but this program will expect a single one
    my $cfg = LoadFile( $self->get_config_file() );
	my %servers;

    foreach my $server (keys($cfg->{servers})) {
		


		
		}

    my @comps;
    my $comps_ref =
      $cfg->{servers}->{ $cfg->{connection}->{siebelServer} }->{components};

    my $comp_groups = $cfg->{servers}->{ $cfg->{connection}->{siebelServer} }
      ->{componentsGroups};

    foreach my $comp_alias ( keys( %{$comps_ref} ) ) {

        my ( $ok_status, $criticality );

        if ( exists( $comps_ref->{$comp_alias}->{OKStatus} ) ) {

            $ok_status = $comps_ref->{$comp_alias}->{OKStatus};

        }
        else {

            $ok_status =
              $comp_groups->{ $comps_ref->{$comp_alias}->{ComponentGroup} }
              ->{OKStatus};

        }

        if ( exists( $comps_ref->{$comp_alias}->{criticality} ) ) {

            $criticality = $comps_ref->{$comp_alias}->{criticality};

        }
        else {

            $criticality =
              $comp_groups->{ $comps_ref->{$comp_alias}->{ComponentGroup} }
              ->{criticality}

        }

        die Nagios::Plugin::Siebel::Srvrmgr::Exception::InvalidCompConf->new()
          unless ( defined($ok_status) and defined($criticality) );

        push(
            @comps,
            Nagios::Plugin::Siebel::Srvrmgr::Action::Check::Component->new(
                {
                    alias       => $comp_alias,
                    description => $comps_ref->{$comp_alias}->{description},
                    componentGroup =>
                      $comps_ref->{$comp_alias}->{ComponentGroup},
                    OKStatus    => $ok_status,
                    criticality => $criticality
                }
            )
        );

    }

    $self->_set_siebel_server(
        Nagios::Plugin::Siebel::Srvrmgr::Action::Check::Server->new(
            {
                name       => $cfg->{connection}->{siebelServer},
                components => \@comps
            }
        )
    );

    $self->_set_daemon(
        Siebel::Srvrmgr::Daemon::Light->new(
            {
                gateway    => $cfg->{connection}->{siebelGateway},
                enterprise => $cfg->{connection}->{siebelEnterprise},
                user       => $cfg->{connection}->{user},
                password   => $cfg->{connection}->{password},
                server     => $cfg->{connection}->{siebelServer},
                bin        => File::Spec->catfile(
                    $cfg->{connection}->{srvrmgrPath},
                    $cfg->{connection}->{srvrmgrExec}
                ),
                use_perl => $self->use_perl(),
                commands => [
                    Siebel::Srvrmgr::Daemon::Command->new(
                        command => 'load preferences',
                        action  => 'LoadPreferences',
                    ),
                    Siebel::Srvrmgr::Daemon::Command->new(
                        command => 'list comp',
                        action  => 'CheckComps',
                        params  => [ $self->get_siebel_server() ]
                    )
                ]
            }
        )
    );

    $self->_set_stash( Siebel::Srvrmgr::Daemon::ActionStash->instance() );

}

sub _validate_alias {

    my $self       = shift;
    my $comp_alias = shift;

    die Nagios::Plugin::Siebel::Srvrmgr::Exception::NotFoundCompAlias->new()
      unless ( $self->get_siebel_server()->has_comp($comp_alias) );

    my $comp = $self->get_siebel_server()->get_comp($comp_alias);

    die Nagios::Plugin::Siebel::Srvrmgr::Exception::InvalidCompAlias->new()
      unless ( defined($comp) );

    $comp->set_isOK(0);    # sanity check

    die Nagios::Plugin::Siebel::Srvrmgr::Exception::CompNotEqual->new(
        { expected => $comp->name(), received => $comp_alias } )
      unless ( $comp->get_alias() eq $comp_alias );

}

sub check_comp {

    my $self        = shift;
    my $server_name = shift;
    my $comp_alias  = shift;

    my $comp = $self->_validate_alias($comp_alias);

    $self->get_daemon()->run();
    $self->get_daemon()->shift_commands();

    $self->get_comp_status($comp);

    return $comp;

}

sub get_comp_status {

    my $self = shift;
    my $comp = shift;

    my $srvrmgr_data = $self->get_stash()->get_stash()->[0];
    weaken($srvrmgr_data);

    die Nagios::Plugin::Siebel::Srvrmgr::Exception::InvalidSrvrmgrData->new()
      unless ( ref($srvrmgr_data) eq 'HASH' );

    my $server_name = $self->get_daemon()->get_server();

    die Nagios::Plugin::Siebel::Srvrmgr::Exception::InvalidServer->new(
        { servername => $server_name } )
      unless ( exists( $srvrmgr_data->{$server_name} ) );

    $comp->set_isOK( $srvrmgr_data->{$server_name}->{ $comp->get_alias() } );

}

__PACKAGE__->meta->make_immutable();

1;
