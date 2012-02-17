package Siebel::Srvrmgr::Daemon::Action;

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon::Action - base class for Siebel::Srvrmgr::Daemon action

=head1 SYNOPSES

This class must be subclassed and the C<do> method overloaded.

An subclass should return true ONLY when was able to identify the type of output received.

This can be accomplish using something like this in the do method:

    sub do {

		my $self = shift;
		my $buffer = shift;

		$self->get_parser()->parse($buffer);

		my $tree = $self->get_parser()->get_parsed_tree();

		foreach my $obj ( @{$tree} ) {

			if ( $obj->isa('Siebel::Srvrmgr::ListParser::Output::MyOutputSubclassName') ) {

				my $data =  $obj->get_data_parsed();

				nstore $data, $self->dump_file();

				return 1;

			}

		}    # end of foreach block

		return 0;
		
	}

Where MyOutputSubclassName is a subclass of Siebel::Srvrmgr::ListParser::Output.

If this kind of output is not identified and the proper return() given, L<Siebel::Srvrmgr::Daemon> can enter in a infinite loop.

=cut

use Moose;
use namespace::autoclean;

=pod

=head1 ATTRIBUTES

=head2 parser

A reference to a L<Siebel::Srvrmgr::ListParser> object. This attribute is required during object creation and is read-only.

=cut

has parser => (
    isa      => 'Siebel::Srvrmgr::ListParser',
    is       => 'ro',
    required => 1,
    reader   => 'get_parser'
);

=pod

=head2 params

An array reference. C<params> is an optional attribute during the object creation and it is used to pass additional parameters. How
those parameters are going to be used is left who is creating subclasses of Siebel::Srvrmgr::Daemon::Action.

=cut

has params => ( isa => 'ArrayRef', is => 'rw' );

=pod

=head1 METHODS

=head2 do

Do something. Every C<do> method must return true (1) if output was used, otherwise false (0);

=cut

sub do {

    my $self = shift;

    die __PACKAGE__ . " must be subclassed to do something useful\n";

}

=pod

=head1 SEE ALSO

=over 4 

=item *

L<Moose>

=item *

L<Siebel::Srvrmgr::ListParser>

=item *

L<Siebel::Srvrmgr::Daemon>

=item *

L<Siebel::Srvrmgr::ListParser::Output>

=back

=cut

__PACKAGE__->meta->make_immutable;
