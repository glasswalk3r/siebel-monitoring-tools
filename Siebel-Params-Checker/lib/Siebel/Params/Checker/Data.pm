package Siebel::Params::Checker::Data;
use warnings;
use strict;
use Exporter qw(import);
# VERSION

our @EXPORT_OK = qw(has_more_servers by_param by_server);

sub has_more_servers {

    my $data_ref = shift;
    my @servers  = ( keys( %{$data_ref} ) );
    my @params   = ( keys( %{ $data_ref->{ $servers[0] } } ) );
    if ( scalar(@servers) > scalar(@params) ) {
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

1;
