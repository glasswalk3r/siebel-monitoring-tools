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
# list it's components available and print a set of 'create component definition'
# commands of the respective components

use warnings;
use strict;
use Siebel::Srvrmgr::Daemon::Heavy;
use Siebel::Srvrmgr::ListParser::Output::ListComp::Server;
use Siebel::Srvrmgr::ListParser::Output::ListParams;
use Siebel::Srvrmgr::Daemon::Command;
use Siebel::Srvrmgr::Exporter::ListCompDef;
use Siebel::Srvrmgr::Exporter::ListComp;
use Siebel::Srvrmgr::Exporter::ListCompTypes;
use File::Spec;
use Getopt::Std;
use Term::Pulse;

$Getopt::Std::STANDARD_HELP_VERSION = 2;

# for stopping Term::Pulse correctly
$SIG{INT} = sub { die "Caught interrupt signal" };

our $VERSION = 1;

sub HELP_MESSAGE {

    my $option = shift;

    if ( ( defined($option) ) and ( ref($option) eq '' ) ) {

        print "'-$option' parameter cannot be null\n";

    }

    print <<BLOCK;

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
	-b: expects as parameter the complete path to the srvrmgr binary file as parameter
	-r: expects as parameter the regular expression to match component alias to export as parameter (case sensitive)

The parameters below are optional:

	-x: exclude mode. If present, the program will exclude component parameters with empty values from the generated 'created component' command
	-q: quiet mode. If present, the program will not put print anything to STDOUT but the "create component" output (see also -o)
	-o: output mode. If present, expects a filename as parameter to print the output to this file instead of STDOUT (default)
	-h: prints this help message and exists

BLOCK

    exit(0);

}

our %opts;

getopts( 's:g:e:u:p:b:r:o:xhq', \%opts );

HELP_MESSAGE() if ( exists( $opts{h} ) );

foreach my $option (qw(s g e u p b r)) {

    HELP_MESSAGE($option) unless ( defined( $opts{$option} ) );

}

pulse_start(
    name   => 'Connecting to Siebel and getting initial data...',
    rotate => 1,
    time   => 1
) unless ( $opts{q} );

my $daemon = Siebel::Srvrmgr::Daemon::Heavy->new(
    {
        server       => $opts{s},
        gateway      => $opts{g},
        enterprise   => $opts{e},
        user         => $opts{u},
        password     => $opts{p},
        bin          => $opts{b},
        is_infinite  => 0,
        read_timeout => 5,
        commands     => [
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
                    action  => 'Siebel::Srvrmgr::Exporter::ListComp'
                }
              )

        ]
    }
);

# "globals"
my ( $DEFS_REF, $TYPES_REF );

my $stash = Siebel::Srvrmgr::Daemon::ActionStash->instance();

$daemon->run();

my $sieb_srv     = $stash->shift_stash();
my $server_comps = $sieb_srv->get_comps();

my $comp_regex = qr/$opts{r}/;

pulse_stop() unless ( $opts{q} );

my $out;

if ( defined( $opts{o} ) ) {

    open( $out, '>:utf8', $opts{o} )
      or die "Cannot create output file $opts{o}: $!\n";

}

my $no_match = 1;

foreach my $comp_alias ( @{$server_comps} ) {

    next unless ( $comp_alias =~ $comp_regex );

    $no_match = 0;

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
    my $params = $stash->shift_stash();

    my $comp = $sieb_srv->get_comp($comp_alias);

# check if the attribute is not already set since the behaviour below was from Siebel 7.5.3 only
    $comp->ct_name( $comp->cc_name(), $daemon, $stash )
      unless ( $comp->ct_name() );
    $comp->ct_alias( $comp->ct_name(), $daemon, $stash )
      unless ( $comp->ct_alias() );

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

    if ( defined( $opts{o} ) ) {

        print $out 'create component definition ', $comp->cc_alias(),
          ' for component type ', $comp->ct_alias(),
          ' component group ', $comp->cg_alias(), ' run mode ',
          $comp->cc_runmode(),
          ' full name "', $comp->cc_name(), '" description "',
          $comp->cc_desc_text(), '" with parameter ', join( ',', @params ),
          ";\n";

    }
    else {

        print "\n", 'create component definition ', $comp->cc_alias(),
          ' for component type ', $comp->ct_alias(),
          ' component group ', $comp->cg_alias(), ' run mode ',
          $comp->cc_runmode(),
          ' full name "', $comp->cc_name(), '" description "',
          $comp->cc_desc_text(), '" with parameter ', join( ',', @params ),
          ";\n\n";

    }

}

close($out) if ( defined($out) );

if ($no_match) {

    warn
"Could not match any component alias to the string '$opts{r}'. Removing the output file (probably empty anyway)...";
    unlink( $opts{o} ) or die "Cannot remove $opts{o}: $!\n";

}

sub get_comp_type_alias {

    my $comp_type_name = shift;
    my $daemon         = shift;
    my $stash          = shift;

    unless ( defined($TYPES_REF) ) {

        $daemon->set_commands(
            [
                Siebel::Srvrmgr::Daemon::Command->new(
                    {
                        command => 'list comp type',
                        action  => 'Siebel::Srvrmgr::Exporter::ListCompTypes'
                    }
                )
            ]
        );

        $daemon->run();
        $TYPES_REF = $stash->shift_stash();

    }

    return $TYPES_REF->{$comp_type_name}->{CT_ALIAS};

}

sub get_comp_type_name {

    my $comp_name = shift;
    my $daemon    = shift;
    my $stash     = shift;

    unless ( defined($DEFS_REF) ) {

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
        $DEFS_REF = $stash->shift_stash();

    }

    return $DEFS_REF->{$comp_name}->{CT_NAME};

}
