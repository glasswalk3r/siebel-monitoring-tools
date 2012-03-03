#!/usr/bin/perl

# this script will use srvrmgr program to connect to a given Siebel Server,
# list it's components available and print to STDOUT a set of 'create component definition'
# commands of the respective components

use warnings;
use strict;
use Siebel::Srvrmgr::Daemon;
use Storable qw(retrieve); # shouldn't be necessary, but there is a bug in Win32 system that requires it
use Siebel::Srvrmgr::ListParser::Output::ListComp::Server;
use Siebel::Srvrmgr::ListParser::Output::ListParams;
use File::Spec::Functions qw(tmpdir);

# be sure to edit the variables below and the key values in the new() method
# as appropriated to your environment

my $siebel_server   = 'foobar';
my $tmp_dir         = tmpdir();
my $comp_types_file = catfile( $tmp_dir, 'listCompTypes.sto' );
my $comps_file      = catfile( $tmp_dir, 'listComp.sto' );
my $comps_defs_file = catfile( $tmp_dir, 'listCompDefs.sto' );
my $bin             = catfile( 'somewhere', 'srvrmgr' );

my $daemon = Siebel::Srvrmgr::Daemon->new(
    {
        server      => $siebel_server,
        gateway     => 'foobar',
        enterprise  => 'siebel',
        user        => 'sadmin',
        password    => 'somepass',
        bin         => $bin,
        is_infinite => 0,
        timeout     => 0,
        commands    => [
            {
                command => 'load preferences',
                action  => 'LoadPreferences',
            },
            {
                command => 'list comp type',
                action  => 'ListCompTypes',
                params  => [$comp_types_file]
            },
            {
                command => 'list comp',
                action  => 'ListComps',
                params  => [$comps_file]
            },
            {
                command => 'list comp def',
                action  => 'ListCompDef',
                params  => [$comps_defs_file]
            }
        ]
    }
);

# simple cache between the calls
unless ( -e $comp_types_file ) {

    $daemon->run();

}

my $comp_types_ref = retrieve($comp_types_file);    # hash reference
my $comp_defs_ref  = retrieve($comps_defs_file);    # hash reference

my $server = Siebel::Srvrmgr::ListParser::Output::ListComp::Server->load(
    $comps_file . "_$siebel_server" );

my $server_comps = $server->get_comps();

my @new_commands;

foreach my $comp_alias ( @{$server_comps} ) {

    my $command =
        'list params for server '
      . $server->get_name()
      . ' component '
      . $comp_alias;

    my $dump_file = $tmp_dir . $comp_alias . '-listParams.sto';

    push( @new_commands,
        { command => $command, action => 'ListParams', params => [$dump_file] }
    );

}

# simple cache between the calls
unless ( -e $tmp_dir . 'EIM-listParams.sto' ) {

    $daemon->set_commands( \@new_commands );
    $daemon->setup_commands();
    $daemon->run()

}

opendir( my $dir, $tmp_dir ) or die "Cannot read $tmp_dir: $!\n";
my @files = readdir($dir);
close($dir);

foreach my $comp_alias ( @{$server_comps} ) {

    my $comp = $server->get_comp($comp_alias);

    $comp->ct_name( $comp_defs_ref->{ $comp->cc_name() }->{CT_NAME} );

    $comp->ct_alias( $comp_types_ref->{ $comp->ct_name() }->{CT_ALIAS} );

# this will not work in Win32, that's why is commented, see CAVEATS of the class POD
#    my $params = Siebel::Srvrmgr::ListParser::Output::ListParams->load( $tmp_dir . $comp_alias . '-listParams.sto' );
    my $params = retrieve( $tmp_dir . $comp_alias . '-listParams.sto' );

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
