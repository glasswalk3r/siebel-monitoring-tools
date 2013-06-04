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
use Siebel::Srvrmgr::Exporter::ListCompDef;
use Siebel::Srvrmgr::Exporter::ListComp;
use Siebel::Srvrmgr::Exporter::ListCompTypes;
use File::Spec;
use Getopt::Std;
use feature qw(say);
use Term::Pulse;

$Getopt::Std::STANDARD_HELP_VERSION = 1;

our $VERSION = 1;

sub HELP_MESSAGE {

    my $option = shift;

    if ( ( defined($option) ) and ( ref($option) eq '' ) ) {

        say "'-$option' parameter cannot be null";

    }

    say <<BLOCK;

export_comps - version $VERSION

This program will connect to a Siebel server and exports all components configuration in the form of "create component" commands.
Those commands can be used with srvrmgr program to recreate those components in another Siebel server. Think of it something like a "Siebel component dumper".
The program will print the "create component" to standard output.

The parameters below are obligatory:

	-s: expects as parameter the Siebel Server name as parameter
	-g: expects as parameter the Siebel Gateway hostname as parameter
	-e: expects as parameter the Siebel Enterprise name as parameter
	-u: expects as parameter the user for authentication as parameter
	-p: expects as parameter the password for authentication as parameter
	-b: expects as parameter the complete path to the srvrmgr program as parameter
	-r: expects as parameter the regular expression to match component alias to export as parameter (case sensitive)

The parameters below are optional:

	-x: if present, the program will exclude component parameters with empty values from the generated 'created component' command
	-h: prints this help message and exists

BLOCK

    exit(0);

}

our %opts;

getopts( 's:g:e:u:p:b:r:xh', \%opts );

HELP_MESSAGE() if ( exists( $opts{h} ) );

foreach my $option (qw(s g e u p b r)) {

    HELP_MESSAGE($option) unless ( defined( $opts{$option} ) );

}

pulse_start(
    name   => 'Connecting to Siebel and getting initial data...',
    rotate => 1,
    time   => 1
);

my $daemon = Siebel::Srvrmgr::Daemon->new(
    {
        server      => $opts{s},
        gateway     => $opts{g},
        enterprise  => $opts{e},
        user        => $opts{u},
        password    => $opts{p},
        bin         => $opts{b},
        is_infinite => 0,
        timeout     => 0,
        commands    => [
            Siebel::Srvrmgr::Daemon::Command->new(
                {
                    command => 'load preferences',
                    action  => 'LoadPreferences',
                }
            ),

# LoadPreferences does not add anything into ActionStash, so it's ok use a second action here
            Siebel::Srvrmgr::Daemon::Command->new(
                {
                    command => 'list comp type',
                    action  => 'Siebel::Srvrmgr::Exporter::ListCompTypes'
                }
            )
        ]
    }
);

my $stash = Siebel::Srvrmgr::Daemon::ActionStash->instance();

$daemon->run();
my $comp_types_ref = $stash->get_stash();
$stash->set_stash( [] );

$daemon->set_commands(
    [
        Siebel::Srvrmgr::Daemon::Command->new(
            {
                command => 'list comp def',
                action  => 'Siebel::Srvrmgr::Exporter::ListCompDef'
            }
        )
    ]
);

$daemon->run();
my $comp_defs_ref = $stash->get_stash();
$stash->set_stash( [] );

$daemon->set_commands(
    [
        Siebel::Srvrmgr::Daemon::Command->new(
            {
                command => 'list comp',
                action  => 'Siebel::Srvrmgr::Exporter::ListComp'
            }
        )
    ]
);

$daemon->run();
my $sieb_srv = $stash->get_stash();
$stash->set_stash( [] );
my $server_comps = $sieb_srv->get_comps();

my $comp_regex = qr/$opts{r}/;

pulse_stop();

foreach my $comp_alias ( @{$server_comps} ) {

    next unless ( $comp_alias =~ $comp_regex );

    my $command =
        'list params for server '
      . $sieb_srv->get_name()
      . ' component '
      . $comp_alias;

    $daemon->set_commands(
        [
            Siebel::Srvrmgr::Daemon::Command->new(
                {
                    command => $command,
                    action  => 'Siebel::Srvrmgr::Exporter::ListParams'
                }
            )
        ]
    );

    $daemon->run();
    my $params = $stash->get_stash();

    my $comp = $sieb_srv->get_comp($comp_alias);

    $comp->ct_name( $comp_defs_ref->{ $comp->cc_name() }->{CT_NAME} );

    $comp->ct_alias( $comp_types_ref->{ $comp->ct_name() }->{CT_ALIAS} );

    my @params;

    foreach my $param_alias ( keys( %{ $params->{data_parsed} } ) ) {

        my $param = $params->{data_parsed}->{$param_alias};

        unless ( ( $param->{PA_SETLEVEL} eq 'SIS_DEFAULT_SET' )
            or ( $param->{PA_SETLEVEL} eq 'SIS_NEVER_SET' ) )
        {

            push( @params, $param_alias . '=' . $param->{PA_VALUE} )
              unless ( ( $param->{PA_VALUE} eq '' ) and ( $opts{x} ) );

        }

    }

    print "\n", 'create component definition ', $comp->cc_alias(),
      ' for component type ', $comp->ct_alias(),
      ' component group ', $comp->cg_alias(), ' run mode ', $comp->cc_runmode(),
      ' full name "', $comp->cc_name(), '" description "',
      $comp->cc_desc_text(), '" with parameter ', join( ',', @params ), ";\n\n";

}
