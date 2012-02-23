package Siebel::Srvrmgr::Daemon::Action::ListParams;

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon::Action::ListParams - subclass of Siebel::Srvrmgr::Daemon::Action to parse list params output

=head1 SYNOPSIS

	use Siebel::Srvrmgr::Daemon::Action::ListParams;

	my $action = Siebel::Srvrmgr::Daemon::Action::ListParams->new(  parser => Siebel::Srvrmgr::ListParser->new(),
																	params => [$filename]);

	$action->do(\@output);


=cut

use Moose;
use namespace::autoclean;

extends 'Siebel::Srvrmgr::Daemon::Action';
with 'Siebel::Srvrmgr::Daemon::Action::Serializable';

=pod

=head1 DESCRIPTION

This subclass of L<Siebel::Srvrmgr::Daemon::Action> will try to find a L<Siebel::Srvrmgr::ListParser::Output::ListParams> object in the given array reference
given as parameter to the C<do> method and stores the parsed data from this object in a serialized file.

=head1 METHODS

=head2 do

This method is overrided from the superclass method, that is still called to validate parameter given.

It will search in the array reference given as parameter: the first object found is serialized to the filesystem
and the function returns 1 in this case. Otherwise it will return 0.

=cut

sub do {

    my $self   = shift;
    my $buffer = shift;    # array reference

	super();

    $self->get_parser()->parse($buffer);

    my $tree = $self->get_parser()->get_parsed_tree();

    foreach my $obj ( @{$tree} ) {

        if ( $obj->isa('Siebel::Srvrmgr::ListParser::Output::ListParams') ) {

            $obj->store( $self->get_dump_file() );

            return 1;

        }

    }    # end of foreach block

    return 0;

}

=pod

=head1 SEE ALSO

=over 2

=item *

L<Siebel::Srvrmgr::Daemon::Action>

=item *

L<Siebel::Srvrmgr::Daemon::Action::Serializable>

=back

=cut

__PACKAGE__->meta->make_immutable;
