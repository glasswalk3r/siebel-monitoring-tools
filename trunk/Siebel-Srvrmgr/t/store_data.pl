use warnings;
use strict;
use utf8;
use YAML::Syck;
use File::Spec;
use Cwd;
use feature 'say';

my %data;

my @keys = (
    'load_preferences',
    'list_comp',
    'list_comp_types',
    'list_params',
    'list_comp_def',
    'list_comp_def_for_component_srproc',
    'list_params_for_srproc',
    'list_servers',
    'list_tasks',
    'list_tasks_for_server_siebfoobar_component_srproc',
    'load_preferences'
);

foreach my $key (@keys) {

    say "Processing $key";
    read_output( \%data, $key );

}

my $filename = shift;
chomp($filename);
DumpFile( $filename, \%data );

sub read_output {

    my $data_ref = shift;    # hash ref
    my $key      = shift;

    my $filename =
      File::Spec->catfile( getcwd(), 'output', 'mock', 'fixed_width',
        $key . '.txt' );

    open( my $in, '<:utf8', $filename ) or die "Cannot read $filename: $!\n";
    my @data = <$in>;
    close($in);

    $data_ref->{$key} = \@data;

    return 1;

}
