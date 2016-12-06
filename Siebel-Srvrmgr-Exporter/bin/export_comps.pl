#!perl

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

use warnings;
use strict;
use Config;
use Siebel::Srvrmgr::ListParser::Output::ListComp::Server 0.24;
use Siebel::Srvrmgr::ListParser::Output::Tabular::ListParams 0.24;
use Siebel::Srvrmgr::Daemon::Command 0.24;
use Siebel::Srvrmgr::Exporter::ListCompDef;
use Siebel::Srvrmgr::Exporter::ListComp;
use Siebel::Srvrmgr::Exporter::ListCompTypes;
use File::Spec;
use Getopt::Long;
use Pod::Usage;
use Siebel::Srvrmgr::Exporter;

# VERSION

my $VERSION = 1;

my $yap;

BEGIN {

    my %params = (
        name      => 'Connecting to Siebel and getting initial data... ',
        rotatable => 1,
        time      => 1
    );

    if ( $Config{useithreads} ) {
        require Term::YAP::iThread;
        $yap = Term::YAP::iThread->new( \%params );
    }
    else {
        require Term::YAP::Process;
        $yap = Term::YAP::Process->new( \%params );
    }

    if ( $Config{osname} eq 'MSWin32' ) {
        require Siebel::Srvrmgr::Daemon::Light;
    }
    else {
        require Siebel::Srvrmgr::Daemon::Heavy;
    }

}

my (
    $server, $gateway, $enterprise, $user,     $pass, $bin,
    $regex,  $output,  $delimiter,  $timezone, $offline
);
my ( $help, $exclude, $quiet, $version );
$help = $exclude = $quiet = 0;
GetOptions(
    'help'         => \$help,
    'server:s'     => \$server,
    'gateway:s'    => \$gateway,
    'enterprise:s' => \$enterprise,
    'user:s'       => \$user,
    'pass:s'       => \$pass,
    'bin:s'        => \$bin,
    'regex=s'      => \$regex,
    'exclude'      => \$exclude,
    'quiet'        => \$quiet,
    'output:s'     => \$output,
    'delimiter:s'  => \$delimiter,
    'timezone:s'   => \$timezone,
    'version'      => \$version,
    'offline:s'    => \$offline
) or pod2usage(1);

pod2usage( -exitval => 0, -verbose => 2 ) if $help;
pod2usage( -exitval => 1, -verbose => 2 )
  unless (
    defined($offline)
    or (    defined($server)
        and defined($gateway)
        and defined($enterprise)
        and defined($user)
        and defined($pass)
        and defined($bin) )
  );

if ($version) {
    print "export_comps - version $VERSION\n";
    exit(0);
}

if (    ( $Config{osname} eq 'MSWin32' )
    and ( not( $Config{useithreads} ) ) )
{
    die
'Sorry, your perl does not support ithreads: this program will not work correctly unless you select the "--quiet" option';
}

my $daemon;

if ( defined($offline) ) {

    #$daemon = Siebel::Srvrmgr::Daemon::Offline->new($offline);

}
else {

    my %options = (
        server       => $server,
        gateway      => $gateway,
        enterprise   => $enterprise,
        user         => $user,
        password     => $pass,
        bin          => $bin,
        time_zone    => ( defined($timezone) ) ? $timezone : 'UTC',
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
    );

    if ( defined($delimiter) ) {
        $options{field_delimiter} = $delimiter;
        print "Using field delimiter '$delimiter'" unless ($quiet);
    }

    if ( $Config{osname} eq 'MSWin32' ) {
        $daemon = Siebel::Srvrmgr::Daemon::Light->new( \%options );
    }
    else {
        $daemon = Siebel::Srvrmgr::Daemon::Heavy->new( \%options );
    }

}

$yap->start() unless ($quiet);

# these variables are global caches for component definitions and component types respectively
my ( $DEFS_REF, $TYPES_REF );
my $stash = Siebel::Srvrmgr::Daemon::ActionStash->instance();
$daemon->run();
my $sieb_srv     = $stash->shift_stash();
my $server_comps = $sieb_srv->get_comps();
my $comp_regex   = qr/$regex/;
$yap->stop() unless ($quiet);
my $out;

if ( defined($output) ) {
    open( $out, '>:utf8', $output )
      or die "Cannot create output file $output: $!\n";
}

my $no_match = 1;

foreach my $comp_alias ( @{$server_comps} ) {
    next unless ( $comp_alias =~ $comp_regex );
    $no_match = 0;
    print "found definitions for component $comp_alias\n" unless ($quiet);
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

# check if the attribute is not already set since the behavior below was from Siebel 7.5.3 only
    unless ( $comp->get_ct_alias ) {
        my $type_name = find_comp_type_name( $comp->get_name, $daemon, $stash );

        if ($type_name) {
            my $type_alias =
              find_comp_type_alias( $type_name, $daemon, $stash );
            $comp->set_ct_alias() if ( defined($type_alias) );

        }

    }

    my @params;
    my @sorted = sort( keys( %{ $params->{data_parsed} } ) );

    foreach my $param_alias (@sorted) {
        my $param = $params->{data_parsed}->{$param_alias};

        # as spotted out by yaroslav.shabalin@gmail.com, old values here
        # were being used only by Siebel 7.5.3 (rest in peace old one!)
        unless ( ( $param->{PA_SETLEVEL} eq 'Default value' )
            or ( $param->{PA_SETLEVEL} eq 'Never set' ) )
        {
            push( @params, $param_alias . '=' . $param->{PA_VALUE} )
              unless ( ( $param->{PA_VALUE} eq '' ) and ($exclude) );
        }

    }

    print "------------ GENERATING OUTPUT -------------\n" unless ($quiet);

    if ( defined($output) ) {
        print $out 'create component definition ', $comp->get_alias(),
          ' for component type ', $comp->get_ct_alias,
          ' component group ', $comp->get_cg_alias, ' run mode ',
          $comp->get_run_mode,
          ' full name "', $comp->get_name, '" description "',
          $comp->get_desc_text(), '" with parameter ', join( ',', @params ),
          ";\n";
    }
    else {
        print "\n", 'create component definition ', $comp->get_alias(),
          ' for component type ', $comp->get_ct_alias(),
          ' component group ', $comp->get_cg_alias(), ' run mode ',
          $comp->get_run_mode(),
          ' full name "', $comp->get_name(), '" description "',
          $comp->get_desc_text(), '" with parameter ', join( ',', @params ),
          ";\n\n";
    }

}

close($out) if ( defined($out) );

if ($no_match) {
    warn
"Could not match any component alias to the string '$regex'. Removing the output file (probably empty anyway)...";
    unlink($output) or die "Cannot remove $output: $!\n";
}

###########################
# SUBS
# the functions below are a "hack" when the component type alias is not available in the "list comp" output

sub find_comp_type_alias {
    my ($comp_type_name, $daemon, $stash) = @_;

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

sub find_comp_type_name {
    my ($comp_name, $daemon, $stash) = @_;

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

    if ( exists( $DEFS_REF->{$comp_name} ) ) {
        return $DEFS_REF->{$comp_name}->{CT_NAME};
    }
    else {
        warn
"could not find the Component Type Name for component alias $comp_name";
        return undef;
    }

}

__END__


export_comps

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

	-h: prints this help message and exits
	-x: exclude mode. If present, the program will exclude component parameters with empty values from the generated 'created component' command
	-q: quiet mode. If present, the program will not put print anything to STDOUT but the "create component" output (see also -o)
	-o <filename>: Print the output to <filename> instead of STDOUT
	-d: delimiter. A single character that will used as delimiter to parse srvrmgr output. Be sure to include "set delimiter <character>" in the srvrmgr preferences file.
	-t: time zone. A string of time zone as listed by DateTime::Timezone all_names() method. If not informed, 'UTC' will be used by default, which should a safe choice for most situations.
