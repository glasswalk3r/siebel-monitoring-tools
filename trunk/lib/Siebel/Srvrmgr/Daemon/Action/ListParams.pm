package Siebel::Srvrmgr::Daemon::Action::ListParams;

=pod
=head1 NAME

Siebel::Srvrmgr::Daemon::Action - base class for Siebel::Srvrmgr::Daemon action

=head1 SYNOPSES

=cut

use Moose;
use namespace::autoclean;

extends 'Siebel::Srvrmgr::Daemon::Action';

has dump_file => ( isa => 'Str', is => 'rw' );

sub BUILD {

    my $self = shift;

    my $params_ref = $self->params();

    my $file = shift( @{$params_ref} );

    $self->dump_file($file) if ( defined($file) );

}

sub do {

    my $self   = shift;
    my $buffer = shift;    # array reference

    $self->get_parser()->parse($buffer);

    my $tree = $self->get_parser()->get_parsed_tree();

    foreach my $obj ( @{$tree} ) {

        if ( $obj->isa('Siebel::Srvrmgr::ListParser::Output::ListParams') ) {

            $obj->store( $self->dump_file() );

            return 1;

        }

    }    # end of foreach block

    return 0;

}

__PACKAGE__->meta->make_immutable;
