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

 # :WORKAROUND:01-01-2014 18:42:35:: could not user super() because
 # it was using a "default" value after calling _set_header_regex
override '_build_header_regex' => sub {

    my $self = shift;

    my $new_sep = '(\s+)?' . $self->get_col_sep();

    $self->_set_header_regex( join( $new_sep, @{ $self->get_header_cols() } ) );

};

# :WORKAROUND:01-01-2014 17:43:39:: used closure to compile the regex only once
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
