package Siebel::Srvrmgr::Daemon::Action::Dumper;

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon::Action::Dumper - subclass for Siebel::Srvrmgr::Daemon::Action to dump buffer content

=head1 SYNOPSIS

See L<Siebel::Srvrmgr::Daemon::Action> for an example.

=head1 DESCRIPTION

This is a subclass of L<Siebel::Srvrmgr::Daemon::Action> that will dump a buffer content (array reference) passed
as parameter to the it's C<do> method.

This class uses L<Data::Dumper> them to print the buffer content to C<STDOUT>.

=cut

use Moose;
use namespace::autoclean;
use Data::Dumper;

extends 'Siebel::Srvrmgr::Daemon::Action';

override 'do' => sub {

    my $self   = shift;
    my $buffer = shift;

    super();

    print Dumper($buffer);

};

=pod

=head1 SEE ALSO

L<Siebel::Srvrmgr::Daemon::Action>

=cut

__PACKAGE__->meta->make_immutable;
