#!/usr/bin/env perl
# just to get automatic version number from Dist::Zilla::Plugin::PkgVersion
package main;

use warnings;
use strict;
use Getopt::Std;
use Siebel::Params::Checker;
use File::HomeDir 1.00;
use File::Spec;
use Template 2.26;

$Getopt::Std::STANDARD_HELP_VERSION = 2;

sub HELP_MESSAGE {

    my $option = shift;

    if ( ( defined($option) ) and ( ref($option) eq '' ) ) {

        print "'-$option' parameter cannot be null\n";

    }

    print <<BLOCK;

scpc - version $main::VERSION

This program will connect to a Siebel server, check desired components parameters and print all information to STDOUT as a table for comparison.

The parameters available are:

    -n: required parameter of the component alias to export as parameter (case sensitive). The component alias must be unique.
    -o: required parameter with the complete pathname to the HTML file to be generated as result
    -c: optional parameter to the complete path to the configuration file (defaults to .scpc.cfg in the user home directory).
        See the Pod of Siebel::Params::Checker for details on the configuration file.

The parameters below are optional:

    -h: prints this help message and exits

Beware that environment variables required to connect to a Siebel Enterprise are expected to be already in place.

BLOCK

    exit(0);

}

our %opts;

getopts( 'n:c:o:h', \%opts );

HELP_MESSAGE() if ( exists( $opts{h} ) );

foreach my $option (qw(n o)) {

    HELP_MESSAGE($option) unless ( defined( $opts{$option} ) );

}

my $cfg_file;
my $default = File::Spec->catfile( File::HomeDir->my_home(), '.scpc.cfg' );

if ( exists( $opts{c} ) ) {

    if ( -r $opts{c} ) {
        $cfg_file = $opts{c};
    }
    else {
        die "file $opts{c} does not exist or is not readable";
    }

}
elsif ( -e $default ) {
    $cfg_file = $default;
}
else {
    die
"No default configuration file available, create it or specify one with -c option";
}

my $data_ref = recover_info( $cfg_file, $opts{n} );
#my $data_ref = {
#    'vmsodcfst005' => {
#        'MinMTServers'    => '1',
#        'MaxMTServers'    => '1',
#        'BusObjCacheSize' => '0',
#        'MaxTasks'        => '20'
#    },
#    'vmsodcfst004' => {
#        'MaxTasks'        => '50',
#        'MinMTServers'    => '1',
#        'MaxMTServers'    => '1',
#        'BusObjCacheSize' => '0'
#    },
#    'vmsodcfst008' => {
#        'MaxMTServers'    => '1',
#        'BusObjCacheSize' => '0',
#        'MinMTServers'    => '1',
#        'MaxTasks'        => '50'
#    }
#};

my ( $header, $rows );

if ( more_servers($data_ref) ) {
    ( $header, $rows ) = by_server($data_ref);
}
else {
    ( $header, $rows ) = by_param($data_ref);
}

my $template = Template->new(
    {
        ENCODING   => 'utf8',
        TRIM       => 1,
        OUTPUT     => $opts{o},
        PRE_CHOMP  => 1,
        POST_CHOMP => 1,
    }
);
my $html;
{
    local $/ = undef;
    $html = <DATA>;
}
close(DATA);
my $vars = {
    title  => "Report of parameters of $opts{n} component",
    header => $header,
    rows   => $rows
};

$template->process( \$html, $vars )
  or die $template->error();

sub more_servers {

    my $data_ref = shift;
    my @servers  = ( keys( %{$data_ref} ) );
    my @params   = ( keys( %{ $data_ref->{ $servers[0] } } ) );
    if ( scalar(@servers) < scalar(@params) ) {
        return 1;
    }
    else {
        return 0;
    }

}

sub by_param {

    my $ref = shift;
    my @rows;
    my @servers = sort( keys( %{$ref} ) );
    my @params  = sort( keys( %{ $ref->{ $servers[0] } } ) );

    foreach my $server (@servers) {
        my @row = ($server);
        foreach my $param (@params) {
            push( @row, $ref->{$server}->{$param} );
        }
        push( @rows, \@row );
    }

    unshift( @params, ' ' );
    return \@params, \@rows;

}

sub by_server {

    my $ref = shift;
    my @rows;
    my @servers = sort( keys( %{$ref} ) );
    my @params  = sort( keys( %{ $ref->{ $servers[0] } } ) );

    foreach my $param (@params) {
        my @row = ($param);
        foreach my $server (@servers) {
            push( @row, $ref->{$server}->{$param} );
        }
        push( @rows, \@row );
    }

    unshift( @servers, ' ' );
    return \@servers, \@rows;

}

__DATA__
<!DOCTYPE html><html><head><style>thead {color:green;}
tbody {color:blue;}
tfoot {color:red;}
table,th,td
{border:1px solid black;}
</style>
<title>[% title %]</title>
</head>
<body>
<table border="1" style="width:300px">
<thead>
<tr>
[% FOREACH column IN header %]
<th>[% column %]</th>
[% END %]
</tr>
</thead>
<tbody>
[% FOREACH row IN rows %]
<tr>
[% FOREACH column IN row %]
<td>[% column %]</td>
[% END %]
</tr>
[% END %]
</table>
</body>
</html>
