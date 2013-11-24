package Siebel::Srvrmgr::ListParser::Output::Tabular::Struct::Delimited;

use Moose;
use MooseX::FollowPBP;
use namespace::autoclean;

extends 'Siebel::Srvrmgr::ListParser::Output::Tabular::Struct';

sub get_fields {

    my $self = shift;
    my $line = shift;

    my $regex = $self->get_col_sep();

    my @fields = split( /$regex/, $line );

    return \@fields;

}

sub define_fields_pattern {

    return 1;

}

__PACKAGE__->meta->make_immutable;
