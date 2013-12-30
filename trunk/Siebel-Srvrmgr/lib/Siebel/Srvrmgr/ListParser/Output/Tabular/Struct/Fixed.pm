package Siebel::Srvrmgr::ListParser::Output::Tabular::Struct::Fixed;

use Moose;
use namespace::autoclean;

extends 'Siebel::Srvrmgr::ListParser::Output::Tabular::Struct';

has fields_pattern => (
    is     => 'ro',
    isa    => 'Str',
    reader => 'get_fields_pattern',
    writer => '_set_fields_pattern'
);

sub define_fields_pattern {

    my $self = shift;
    my $line = shift;

    my $separator = $self->get_col_sep();
    my $comp_sep  = qr/$separator/;

    # :TODO:30-12-2013:: some logging would ne nice here
    if ( $line =~ $comp_sep ) {

        my @columns = split( /$separator/, $line );

        my $pattern;

        foreach my $column (@columns) {

# :WARNING   :09/05/2013 12:19:37:: + 2 because of the spaces after the "---" that will be trimmed
            $pattern .= 'A' . ( length($column) + 2 );

        }

        $self->_set_fields_pattern($pattern);
        return 1;

    }
    else {

        return 0;

    }

}

sub get_fields {

    my $self = shift;
    my $line = shift;

    my @fields = unpack( $self->get_fields_pattern(), $line );

    return \@fields;

}

__PACKAGE__->meta->make_immutable;
