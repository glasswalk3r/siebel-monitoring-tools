package Siebel::Srvrmgr::ListParser::OutputFactory;

use warnings;
use strict;
use MooseX::AbstractFactory;
use feature 'switch';

our %table_mapping = (
    'list comp'        => 'ListComp',
    'list params'      => 'ListParams',
    'list comp def'    => 'ListCompDef',
    'greetings'        => 'Greetings',
    'list comp type'   => 'ListCompTypes',
    'load preferences' => 'LoadPreferences'
);

implementation_class_via sub {

    my $last_cmd_type = shift;
    my $object_data   = shift;    # hash ref

    my $class;

    given ($last_cmd_type) {

        when ( $_ eq 'list_params' ) {
            $class = $table_mapping{'list params'};
        }
        when ( $_ eq 'list_comp_def' ) {
            $class = $table_mapping{'list comp def'};
        }
        when ( $_ eq 'list_comp_type' ) {
            $class = $table_mapping{'list comp type'};
        }
        when ( $_ eq 'list_comp' ) { $class = $table_mapping{'list comp'}; }
        when ( $_ eq 'greetings' ) { $class = $table_mapping{greetings}; }
        when ( $_ eq 'load_preferences' ) {
            $class = $table_mapping{'load preferences'};
        }
        default { die "Cannot defined a class for command $last_cmd_type"; }

    }

    return 'Siebel::Srvrmgr::ListParser::Output::' . $class;

};

1;
