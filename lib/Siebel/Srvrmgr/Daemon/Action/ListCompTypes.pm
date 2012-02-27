package Siebel::Srvrmgr::Daemon::Action::ListCompTypes;

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon::Action::ListCompTypes - subclass for parsing list comp types command output

=head1 SYNOPSIS

	use Siebel::Srvrmgr::Daemon::Action::ListCompTypes;

	my $action = Siebel::Srvrmgr::Daemon::Action::ListCompTypes->new({  parser => Siebel::Srvrmgr::ListParser->new(), 
																	params => [$myDumpFile]});

	$action->do(\@output);

=cut

use Moose;
use namespace::autoclean;
use Storable qw(nstore);

extends 'Siebel::Srvrmgr::Daemon::Action';
with 'Siebel::Srvrmgr::Daemon::Action::Serializable';

=pod

=head1 DESCRIPTION

This subclass of L<Siebel::Srvrmgr::Daemon::Action> will try to find a L<Siebel::Srvrmgr::ListParser::Output::ListCompTypes> object in the given array reference
given as parameter to the C<do> method and stores the parsed data from this object in a serialized file. 

=head1 METHODS

=head2 do

This method is overrided from the superclass method, that is still called to validate parameter given.

It will search in the array reference given as parameter: the first object found is serialized to the filesystem
and the function returns 1 in this case. Otherwise it will return 0.

=cut

override 'do' => sub {

    my $self   = shift;
    my $buffer = shift;    # array reference

    super();

    $self->get_parser()->parse($buffer);

    my $tree = $self->get_parser()->get_parsed_tree();

    foreach my $obj ( @{$tree} ) {

        if ( $obj->isa('Siebel::Srvrmgr::ListParser::Output::ListCompTypes') ) {

            my $data = $obj->get_data_parsed();

            nstore $data, $self->get_dump_file();

            return 1;

        }

    }    # end of foreach block

    return 0;

};

=pod

=head1 SEE ALSO

=over 4

=item *

L<Siebel::Srvrgmr::Daemon::Action>

=item *

L<Storable>

=item *

L<Siebel::Srvrmgr::ListParser::Output::ListCompDef>

=item *

L<Siebel::Srvrmgr::Daemon::Action::Serializable>

=back

=cut

__PACKAGE__->meta->make_immutable;
