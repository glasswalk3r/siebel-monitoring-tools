package Siebel::Srvrmgr::Daemon::Action;

=pod
=head1 NAME

Siebel::Srvrmgr::Daemon::Action - base class for Siebel::Srvrmgr::Daemon action

=head1 SYNOPSES

=cut

use Moose;
use namespace::autoclean;

has parser => (
    isa      => 'Siebel::Srvrmgr::ListParser',
    is       => 'ro',
    required => 1,
    reader   => 'get_parser'
);
has params => ( isa => 'ArrayRef', is => 'rw' );


# every do method must return 1 if output was used, otherwise 0
sub do {

    my $self = shift;

    die __PACKAGE__ . " must be subclassed to do something useful\n";

}

__PACKAGE__->meta->make_immutable;
