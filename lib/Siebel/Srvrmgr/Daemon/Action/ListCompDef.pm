package Siebel::Srvrmgr::Daemon::Action::ListCompDef;

=pod
=head1 NAME

Siebel::Srvrmgr::Daemon::Action::ListCompDef - subclass of Siebel::Srvrmgr::Daemon::Action to stored parsed list comp def output

=head1 SYNOPSES

	use Siebel::Srvrmgr:Daemon::Action::ListCompDef;

		$action = $class->new(
			{
                parser =>
                  Siebel::Srvrmgr::ListParser->new( { is_warn_enabled => 1 }, 
				params => ['myStorableFile']
            }
		);

		$action->do(\@data);

=cut

use namespace::autoclean;
use Storable qw(nstore);
use Moose;

extends 'Siebel::Srvrmgr::Daemon::Action';

=pod

=head1 DESCRIPTION

This subclass will try to find a L<Siebel::Srvrmgr::ListParser::Output::ListCompDef> object in the given array reference
given as parameter to the C<do> method and stores the parsed data from this object C<get_params> method into a file using
L<Storable> C<nstore> function.

=head1 ATTRIBUTES

Inherits all attributes from superclass.

=head2 dump_file

This attribute is a string used to indicate in which file the data from L<Siebel::Srvmrgr::ListParser::Output::ListCompDef> should
be serialized into the OS filesystem. The string can be a complete path or just the filename.

=cut

has dump_file => (
    isa    => 'Str',
    is     => 'rw',
    reader => 'get_dump_file',
    writer => 'set_dump_file'
);

=pod

=head1 METHODS

=head2 get_dump_file

Returns the string stored in the attribute C<dump_file>.

=head2 set_dump_file

Sets the attribute C<dump_file>. Expects a string as parameter.

=head2 BUILD

Right after object creation this method will process the C<params> attribute and retrieve the first index of the array reference
to define the C<dump_file> attribute using the method C<set_dump_file>.

If the C<params> attribute is an empty reference, the method wil raise an exception.

=cut

sub BUILD {

    my $self = shift;

    my $params_ref = $self->get_params();

    unless ( ( defined($params_ref) ) and ( scalar( @{$params_ref} ) >= 1 ) ) {

        die
          'Must have at least one value in the params attribute array reference'

    }

    my $file = shift( @{$params_ref} );

    $self->set_dump_file($file) if ( defined($file) );

}

=pod

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

        if ( $obj->isa('Siebel::Srvrmgr::ListParser::Output::ListCompDef') ) {

            my $data = $obj->get_data_parsed();

            nstore $data, $self->get_dump_file();

            return 1;

        }

    }    # end of foreach block

    return 0;

};

=pod

=head1 SEE ALSO

=over 3

=item *

L<Siebel::Srvrgmr::Daemon::Action>

=item *

L<Storable>

=item *

L<Siebel::Srvrmgr::ListParser::Output::ListCompDef>

=back

=cut

__PACKAGE__->meta->make_immutable;
