package Siebel::Srvrmgr::Daemon::Action;

=pod
=head1 NAME

Siebel::Srvrmgr::Daemon::Action - base class for Siebel::Srvrmgr::Daemon action

=head1 SYNOPSES

This class must be subclassed and the do method overloaded.

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

If this kind of output is not identified and the proper return() given, Siebel::Srvrmgr::Daemon can enter in a loop.

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
