#!/usr/bin/perl

#    COPYRIGHT AND LICENCE
#
#    This software is copyright (c) 2012 of Alceu Rodrigues de Freitas Junior, arfreitas@cpan.org
#
#    This file is part of Siebel Monitoring Tools.
#
#    Siebel Monitoring Tools is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    Siebel Monitoring Tools is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with Siebel Monitoring Tools.  If not, see <http://www.gnu.org/licenses/>.

# this script will use srvrmgr program to connect to a given Siebel Server,
# list it's components available and print to STDOUT a set of 'create component definition'
# commands of the respective components

use warnings;
use strict;
use Siebel::Srvrmgr::Daemon;
use Siebel::Srvrmgr::ListParser::Output::ListComp::Server;
use Siebel::Srvrmgr::ListParser::Output::ListParams;
use Siebel::Srvrmgr::Daemon::Command;
use File::Spec::Functions qw(tmpdir catfile);
use Getopt::Long;

# be sure to edit the variables below and the key values in the new() method
# as appropriated to your environment

my $siebel_server = 'siebappdev';
my $tmp_dir       = tmpdir();
my $bin = catfile( 'C:', 'Siebel', '8.1', 'Client', 'BIN', 'srvrmgr.exe' );

my $daemon = Siebel::Srvrmgr::Daemon->new(
    {
        server      => $siebel_server,
        gateway     => 'siebappdev',
        enterprise  => 'sbl_dev',
        user        => 'sadmin',
        password    => 'sadmin',
        bin         => $bin,
        is_infinite => 0,
        timeout     => 0,
        commands    => [
            Siebel::Srvrmgr::Daemon::Command->new(
                {
                    command => 'load preferences',
                    action  => 'LoadPreferences',
                }
            ),
            Siebel::Srvrmgr::Daemon::Command->new(
                {
                    command => 'list comp type',
                    action  => 'ListCompTypes'
                }
            ),
            Siebel::Srvrmgr::Daemon::Command->new(
                {
                    command => 'list comp',
                    action  => 'ListComps'
                }
            ),
            Siebel::Srvrmgr::Daemon::Command->new(
                {
                    command => 'list comp def',
                    action  => 'ListCompDef'
                }
            )
        ]
    }
);

$daemon->run();

my $server;
my $server_comps = $server->get_comps();

my @new_commands;

foreach my $comp_alias ( @{$server_comps} ) {

    my $command =
        'list params for server '
      . $server->get_name()
      . ' component '
      . $comp_alias;

    push(
        @new_commands,
        Siebel::Srvrmgr::Daemon::Command->new(
            {
                command => $command,
                action  => 'ListParams'
            }
        )
    );

}

$daemon->set_commands( \@new_commands );
$daemon->setup_commands();
$daemon->run();

opendir( my $dir, $tmp_dir ) or die "Cannot read $tmp_dir: $!\n";
my @files = readdir($dir);
close($dir);

foreach my $comp_alias ( @{$server_comps} ) {

    my $comp = $server->get_comp($comp_alias);

    #    $comp->ct_name( $comp_defs_ref->{ $comp->cc_name() }->{CT_NAME} );

    #    $comp->ct_alias( $comp_types_ref->{ $comp->ct_name() }->{CT_ALIAS} );

    my $params = Siebel::Srvrmgr::ListParser::Output::ListParams->load(
        $tmp_dir . $comp_alias . '-listParams.sto' );

    my @params;

    foreach my $param_alias ( keys( %{ $params->{data_parsed} } ) ) {

        my $param = $params->{data_parsed}->{$param_alias};

        unless ( ( $param->{PA_SETLEVEL} eq 'SIS_DEFAULT_SET' )
            or ( $param->{PA_SETLEVEL} eq 'SIS_NEVER_SET' ) )
        {

            push( @params, $param_alias . '=' . $param->{PA_VALUE} );

        }

    }

    print "\n", 'create component definition ', $comp->cc_alias(),
      ' for component type ', $comp->ct_alias(),
      ' component group ', $comp->cg_alias(), ' run mode ', $comp->cc_runmode(),
      ' full name "', $comp->cc_name(), '" description "',
      $comp->cc_desc_text(), '" with parameter ', join( ',', @params ), ";\n\n";

}
