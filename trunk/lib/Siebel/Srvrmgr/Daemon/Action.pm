package Siebel::Srvrmgr::Daemon::Action;

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon::Action - base class for Siebel::Srvrmgr::Daemon action

=head1 SYNOPSIS

This class must be subclassed and the C<do> method overloaded.

An subclass should return true ONLY when was able to identify the type of output received. Beware that the output expected must include also
the command executed or the L<Siebel::Srvrmgr::ListParser> object will not be able to identify the type of the output (L<Siebel::Srvrmgr::Daemon> does that).

This can be accomplish using something like this in the C<do> method:

    sub do {

		my $self = shift;
		my $buffer = shift;

		$self->get_parser()->parse($buffer);

		my $tree = $self->get_parser()->get_parsed_tree();

		foreach my $obj ( @{$tree} ) {

			if ( $obj->isa('Siebel::Srvrmgr::ListParser::Output::MyOutputSubclassName') ) {

				my $data =  $obj->get_data_parsed();

                # do something

				return 1;

			}

		}    # end of foreach block

		return 0;
		
	}

Where MyOutputSubclassName is a subclass of L<Siebel::Srvrmgr::ListParser::Output>.

If this kind of output is not identified and the proper C<return> given, L<Siebel::Srvrmgr::Daemon> can enter in a infinite loop.

=cut

use Moose;
use MooseX::Params::Validate;
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
those parameters are going to be used is left who is creating subclasses of L<Siebel::Srvrmgr::Daemon::Action>.

This attribute is read-only.

=cut

has params => ( isa => 'ArrayRef', is => 'ro', reader => 'get_params' );

=pod

=head1 METHODS

=head2 get_parser

Returns the L<Siebel::Srvrmgr::ListParser> object stored into the C<parser> attribute.

=head2 get_params

Returns the array reference stored in the C<params> attribute.

=head2 do

This method expects to receive a array reference (with the content to be parsed) as parameter and it will do something with it. Usually this should be
identify the type of output received, giving it to the proper parse and processing it somehow.

Every C<do> method must return true (1) if output was used, otherwise false (0);

Actually this method will only validate if the parameter is an array reference or not. Subclasses must override
C<do> to actually to something with the array reference content (see C<override> method in L<Moose::Manual::MethodModifiers>).

=cut

sub do {

    my $self = shift;

    my ($buffer) = pos_validated_list( \@_, { isa => 'ArrayRef' } );

    return 1;

}

=pod

=head1 CAVEATS

This class may be changed to a role instead of a superclass in the future since it's methods could be used by different classes.

=head1 SEE ALSO

=over 6

=item *

L<Moose>

=item *

L<Moose::Manual::MethodModifiers>

=item *

L<MooseX::Params::Validate>

=item *

L<Siebel::Srvrmgr::ListParser>

=item *

L<Siebel::Srvrmgr::Daemon>

=item *

L<Siebel::Srvrmgr::ListParser::Output>

=back

=cut

__PACKAGE__->meta->make_immutable;