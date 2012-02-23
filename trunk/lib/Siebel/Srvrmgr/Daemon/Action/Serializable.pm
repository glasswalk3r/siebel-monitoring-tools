package Siebel::Srvrmgr::Daemon::Action::Serializable;

use Moose::Role;

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon::Action::Serializable - role for serializable subclasses of Siebel::Srvrmgr::Daemon::Action

=head1 DESCRIPTION

This class is a role, not a subclass of L<Siebel::Srvrmgr::Daemon::Action>. It is intended to be used by subclasses that
needs serialization to the filesystem.

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

If the C<params> attribute is an empty reference, the method wil raise an exception. If the value given is undefined or an empty
string, an exception will be raised as well.

=cut

sub BUILD {

    my $self = shift;

    my $params_ref = $self->get_params();

    unless ( ( defined($params_ref) ) and ( scalar( @{$params_ref} ) >= 1 ) ) {

        die
          'Must have at least one value in the params attribute array reference'

    }

    my $file = shift( @{$params_ref} );

    if ( ( defined($file) ) and ( $file ne '' ) ) {

        $self->set_dump_file($file) if ( defined($file) );

    }
    else {

        die 'dump_file attribute must be defined';

    }

}

=pod

=head1 SEE ALSO

L<Siebel::Srvrmgr::Daemon::Action>

=cut

1;
