package Siebel::Params::Checker;
$Siebel::Params::Checker::VERSION = '0.001';

=pod

=head1 NAME

Siebel::Params::Checker - Perl module to extract and show Siebel component parameters between servers

=head1 DESCRIPTION

This modules provides a interface to a Siebel Enterprise to search and extract parameters from a specific Siebel component from all Siebel Server it is available.

=head1 EXPORTS

The C<recover_info> function is the only one exported by default.

=cut

use strict;
use warnings;
use Siebel::Srvrmgr::Daemon::Heavy;
use Siebel::Srvrmgr::ListParser::Output::ListComp::Server;
use Siebel::Srvrmgr::ListParser::Output::Tabular::ListParams;
use Siebel::Srvrmgr::Daemon::Command;
use Config::Tiny 2.23;
use Set::Tiny 0.03;
use Siebel::Params::Checker::ListComp;
use Siebel::Params::Checker::ListParams;
use Exporter 'import';
use Data::Dumper;

our @EXPORT = qw(recover_info);

sub recover_info {

    my ( $cfg_file, $comp_regex ) = @_;
    my $cfg = Config::Tiny->read($cfg_file);
    my $wanted_params =
      Set::Tiny->new( ( split( ',', $cfg->{SEARCH}->{parameters} ) ) );

    my $daemon = Siebel::Srvrmgr::Daemon::Heavy->new(
        {
            gateway         => $cfg->{GENERAL}->{gateway},
            enterprise      => $cfg->{GENERAL}->{enterprise},
            user            => $cfg->{GENERAL}->{user},
            password        => $cfg->{GENERAL}->{password},
            field_delimiter => $cfg->{GENERAL}->{field_delimiter},
            bin             => $cfg->{GENERAL}->{srvrmgr},
            time_zone       => 'UTC',
            read_timeout    => 5,
            commands        => [
                Siebel::Srvrmgr::Daemon::Command->new(
                    {
                        command => 'load preferences',
                        action  => 'LoadPreferences',
                    }
                ),

# LoadPreferences does not add anything into ActionStash, so it's ok use a second action here
                Siebel::Srvrmgr::Daemon::Command->new(
                    {
                        command => 'list comp',
                        action  => 'Siebel::Params::Checker::ListComp'
                    }
                  )

            ]
        }
    );

    my $stash = Siebel::Srvrmgr::Daemon::ActionStash->instance();

    $daemon->run();
    my %data;
    my $servers_ref = $stash->get_stash();
    $stash->set_stash( [] );

    foreach my $server ( @{$servers_ref} ) {

        my $server_comps = $server->get_comps();
        my $server_name  = $server->get_name();
        print "going over $server_name\n";
        $data{$server_name} = {};

        foreach my $comp_alias ( @{$server_comps} ) {

            next unless ( $comp_alias =~ $comp_regex );
            my $command =
                'list params for server '
              . $server_name
              . ' component '
              . $comp_alias;
            $daemon->set_commands(
                [
                    Siebel::Srvrmgr::Daemon::Command->new(
                        {
                            command => $command,
                            action  => 'Siebel::Params::Checker::ListParams'
                        }
                    )
                ]
            );
            $daemon->run();

            my $params_ref = $stash->shift_stash;

            foreach my $param_alias ( keys( %{$params_ref} ) ) {
                if ( $wanted_params->has($param_alias) ) {
                    $data{$server_name}->{$param_alias} =
                      $params_ref->{$param_alias}->{PA_VALUE};
                }
            }

        }

        delete( $data{$server_name} )
          unless ( keys( %{ $data{$server_name} } ) > 0 );

    }

    return \%data;

}

1;
