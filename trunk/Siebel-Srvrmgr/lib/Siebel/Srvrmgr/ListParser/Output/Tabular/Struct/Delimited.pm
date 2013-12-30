package Siebel::Srvrmgr::ListParser::Output::Tabular::Struct::Delimited;

use Moose;
use Carp;
use namespace::autoclean;

extends 'Siebel::Srvrmgr::ListParser::Output::Tabular::Struct';

has trimmer => (
    is      => 'ro',
    isa     => 'CodeRef',
    reader  => 'get_trimmer',
    builder => '_build_trimmer'
);

sub _build_trimmer {

    my $r_spaces = qr/\s+$/;

    return sub {

        my $values_ref = shift;

        for ( my $i = 0 ; $i <= $#{$values_ref} ; $i++ ) {

            $values_ref->[$i] =~ s/$r_spaces//;

        }

        return 1;

      }

}

sub get_fields {

    my $self = shift;
    my $line = shift;

    my $fields_ref = $self->split_fields($line);

    $self->get_trimmer()->($fields_ref);

    return $fields_ref;

}

sub BUILD {

    my $self = shift;
    my $args = shift;

    confess 'col_sep is a required attribute for ' . __PACKAGE__ . ' instances'
      unless ( defined( $args->{col_sep} ) );

    my $sep = $self->get_col_sep();

    #escape the char to be used in a regex
    $self->_set_col_sep( '\\' . $sep );

}

sub define_fields_pattern {

    return 1;

}

__PACKAGE__->meta->make_immutable;
