package Siebel::Srvrmgr::ListParser::OutputFactory;

use warnings;
use strict;
use MooseX::AbstractFactory;
use feature 'switch';

# :TODO:4/1/2012 15:53:27:: create a module to share compiled regex between modules
our $list_params   = qr/list\sparams\sfor\sserver\s\w+\sfor\scomponent\s\w+/;
our $list_comp_def = qr/list\scomp\sdef\s\w+/;

our %table_mapping = (
    'list comp'        => 'ListComp',
    'list params'      => 'ListCompParams',
    'list comp def'    => 'ListCompDef',
    'greetings'        => 'Greetings',
    'list comp type'   => 'ListCompTypes',
    'load preferences' => 'LoadPreferences'
);

implementation_class_via sub {

    my $last_cmd    = shift;
    my $object_data = shift;    # hash ref

    my $class;

    given ($last_cmd) {

        when ( $_ eq 'list_comp_params' ) {
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
        default { die "Cannot defined a class for command $last_cmd"; }

    }

    return 'Siebel::Srvrmgr::ListParser::Output::' . $class;

};

1;
