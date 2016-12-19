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
use Siebel::Srvrmgr::ListParser::Output::ListComp::Server 0.28;
use Siebel::Srvrmgr::ListParser::Output::Tabular::ListParams 0.28;
use Siebel::Srvrmgr::Daemon::Command 0.28;
use Siebel::Srvrmgr::Daemon::Offline 0.28;
use Siebel::Srvrmgr::Daemon::Heavy 0.28;
use Siebel::Srvrmgr::Daemon::Light 0.28;
use Siebel::Srvrmgr::Connection 0.28;
use Siebel::Srvrmgr::Exporter::ListCompDef;
use Siebel::Srvrmgr::Exporter::ListComp;
use Siebel::Srvrmgr::Exporter::ListCompTypes;
use Siebel::Srvrmgr::Exporter::ListParams;
use File::Spec;
use Getopt::Long;
use Pod::Usage 1.69;
use Siebel::Srvrmgr::Exporter;

# VERSION
my $class;
my %params = (
    name      => 'Starting... ',
    rotatable => 1,
    time      => 1
);

BEGIN {

    if ( $Config{useithreads} ) {
        require Term::YAP::iThread;
        $class = 'Term::YAP::iThread';
    }
    else {
        require Term::YAP::Process;
        $class = 'Term::YAP::Process';
    }

}

my $yap = $class->new( \%params );

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

if ($version) {
    print "export_comps.pl - version $VERSION\n";
    exit(0);
}

pod2usage( -exitval => 1, -verbose => 2 )
  unless (
    defined($regex)
    and (
        defined($offline)
        or (    defined($server)
            and defined($gateway)
            and defined($enterprise)
            and defined($user)
            and defined($pass)
            and defined($bin) )
    )
  );

if (    ( $Config{osname} eq 'MSWin32' )
    and ( not( $Config{useithreads} ) ) )
{
    die
'Sorry, your perl does not support ithreads: this program will not work correctly unless you select the "--quiet" option';
}

my ( $daemon, $conn );
my %options = (
    time_zone => ( defined($timezone) ) ? $timezone : 'UTC',
    read_timeout => 5,
    commands     => [
        Siebel::Srvrmgr::Daemon::Command->new(
            {
                command => 'load preferences',
                action  => 'LoadPreferences',
            }
        ),
        Siebel::Srvrmgr::Daemon::Command->new(
            {
                command => 'list comp',
                action  => 'Siebel::Srvrmgr::Exporter::ListComp'
            }
          )

    ]
);

if ( defined($offline) ) {
    print "Running in offline mode\n";
    $options{output_file} = $offline;

    if ($delimiter) {
        $options{field_delimiter} = $delimiter;
    }

    $daemon = Siebel::Srvrmgr::Daemon::Offline->new( \%options );
    my $cmds_ref = $daemon->get_commands;
    push(
        @{$cmds_ref},
        Siebel::Srvrmgr::Daemon::Command->new(
            {
                command => 'list params for server foo component bar',
                action  => 'Siebel::Srvrmgr::Exporter::ListParams'
            }
        )
    );
    $daemon->set_commands($cmds_ref);

}
else {

    if ( defined($delimiter) ) {
        $options{field_delimiter} = $delimiter;
        print "Using field delimiter '$delimiter'" unless ($quiet);
        $conn = Siebel::Srvrmgr::Connection->new(
            {
                server          => $server,
                gateway         => $gateway,
                enterprise      => $enterprise,
                user            => $user,
                password        => $pass,
                bin             => $bin,
                field_delimiter => $delimiter
            }
        );
    }
    else {
        $conn = Siebel::Srvrmgr::Connection->new(
            {
                server     => $server,
                gateway    => $gateway,
                enterprise => $enterprise,
                user       => $user,
                password   => $pass,
                bin        => $bin
            }
        );
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

# Offline should ignore the parameter
$daemon->run($conn);
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
    my ( $params, $comp );

    # no sense asking to execute dinamically defined commands
    unless ( defined($offline) ) {
        $daemon->set_commands(
            [
                Siebel::Srvrmgr::Daemon::Command->new(
                    {
                        command => (
                                'list params for server '
                              . $sieb_srv->get_name()
                              . ' component '
                              . $comp_alias
                        ),
                        action => 'Siebel::Srvrmgr::Exporter::ListParams'
                    }
                )
            ]
        );
        $daemon->run($conn);
        $params = $stash->shift_stash();
        $comp   = $sieb_srv->get_comp($comp_alias);

# check if the attribute is not already set since the behavior below was from Siebel 7.5.3 only
        unless ( $comp->get_ct_alias ) {

            if ( $daemon->isa('Siebel::Srvrmgr::Daemon::Offline') ) {
                die
"offline data must contain CT_ALIAS information for components, cannot continue";
            }
            else {
                my $type_name =
                  find_comp_type_name( $comp->get_name, $daemon, $stash,
                    $conn );

                if ($type_name) {
                    my $type_alias =
                      find_comp_type_alias( $type_name, $daemon, $stash,
                        $conn );
                    $comp->set_ct_alias() if ( defined($type_alias) );

                }

            }

        }

    }
    else {
        $params = $stash->shift_stash();
        $comp   = $sieb_srv->get_comp($comp_alias);
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
    my ( $comp_type_name, $daemon, $stash, $conn ) = @_;

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
        $daemon->run($conn);
        $TYPES_REF = $stash->shift_stash();
    }

    return $TYPES_REF->{$comp_type_name}->{CT_ALIAS};
}

sub find_comp_type_name {
    my ( $comp_name, $daemon, $stash, $conn ) = @_;

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
        $daemon->run($conn);
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

=pod

=head1 NAME

export_comps.pl - program to export components from a Siebel Enterprise

=head1 SYNOPSIS

    export_comps.pl --regex '^Foobar' --server myserver --gateway mygateway --enterprise myenterprise --user user --password password --bin /foobar/srvrmgr
    export_comps.pl --regex '^Foobar' --offline /foobar/subdir/spool.txt

=head1 DESCRIPTION

This program will connect to a Siebel server and exports all components configuration in the form of "create component" commands.
Those commands can be used with srvrmgr program to recreate those components in another Siebel server. Think of it something like a "Siebel component dumper".
The program will print the "create component" to standard output.

The parameter below is obligatory for any case:

	--regex<regular expression>: expects as parameter the regular expression to match component alias to export as parameter (case sensitive)

The parameters below are obligatory if you want to connect to a live Siebel Enterprise:

	--server <SIEBEL SERVER NAME>: expects as parameter the Siebel Server name as parameter
	--gateway <SIEBEL GATEWAY NAME>: expects as parameter the Siebel Gateway hostname as parameter
	--enterprise <SIEBEL ENTERPRISE NAME>: expects as parameter the Siebel Enterprise name as parameter
	--user <LOGIN>: expects as parameter the user for authentication as parameter
	--pass <PASSWORD>: expects as parameter the password for authentication as parameter
	--bin <PATH TO SRVRMGR>: expects as parameter the complete path to the srvrmgr binary file as parameter

If you want to work with a offline, output file generated with srvrmgr spool command, then the parameter below will be obligatory:

    --offline <PATH TO OUTPUT FILE>: expects as parameter the full path to a output file generated with srvrmgr spool command. This output file must contain
      the exact sequence of commands and respective output as this program would execute in a live system ("load preferences", "list comp", "list params for server <SERVER> component <COMPONENT ALIAS>).
      Of course, the output must contain the component alias identified by the --regex parameter or no output will be generated. Setting this parameter will make the program to ignore the connection related
      parameters.

The parameters below are optional:

	--help: prints this help message and exits
	--exclude: exclude mode. If present, the program will exclude component parameters with empty values from the generated 'created component' command
	--quiet: quiet mode. If present, the program will not put print anything to STDOUT but the "create component" output (see also -o)
	--output <PATH TO OUTPUT FILE>: Print the output to <filename> instead of STDOUT
	--delimiter <CHARACTER>: delimiter. A single character that will used as delimiter to parse srvrmgr output. Be sure to include "set delimiter <character>" in the srvrmgr preferences file.
	--timezone <TIMEZONE>: time zone. A string of time zone as listed by DateTime::Timezone all_names() method. If not informed, 'UTC' will be used by default, which should a safe choice for most situations.

=cut
