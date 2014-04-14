package Siebel::Srvrmgr::Daemon::ActionStash;

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon::ActionStash - singleton to stash data returned by Siebel::Srvrmgr::Daemon::Action subclasses

=head1 SYNOPSIS

    package MyAction;
    use Moose;
    use namespace::autoclean;

    extends 'Siebel::Srvrmgr::Daemon::Action';

    my $stash = Siebel::Srvrmgr::Daemon::ActionStash->instance();
	$stash->set_stash([{foobar => foobar}, [qw(one two three)]]);

    package main;

	my $stash = Siebel::Srvrmgr::Daemon::ActionStash->instance();

    # do something with the get_stash method

=head1 DESCRIPTION

This class was created to enable the possibility to retrieve data from an L<Siebel::Srvrmgr::Daemon::Action> subclass invoked by L<Siebel::Srvrmg::Daemon> without
the need to return data from within the objects.

Since Siebel::Srvrmgr::Daemon::ActionStash is a singleton, a reference of the already instantied object will always be returned when calling C<instance>. So, before
calling the method C<run> from a L<Siebel::Srvrmgr::Daemon> class instance, it is just a matter to call C<instance> and inside the L<Siebel::Srvrmgr::Daemon::Action> subclass, 
call the C<initialize> method with the data that should be returned as parameter.

The drawnback from this technique is that two Action objects cannot used the same Stash at the same time or data will be replace/lost: a ActionStash instance should be used 
exclusively by a single Action subclass. If you have need to returned data from several L<Siebel::Srvrmgr::Daemon::Action> subclasses you must use a different method.

Considering this situation, the interface of this class should be considered experimental and may be changed in the future releases.

=cut

use MooseX::Singleton;

=pod

=head1 ATTRIBUTES

=head2 stash

This attribute is a array reference of references. This means that it will accept B<any> reference to some data structure that you think it will be 
useful (including objects).

If undefined, this attribute will returned an empty array reference.

=cut

has stash => (
    is       => 'rw',
    isa      => 'ArrayRef[Ref]',
    required => 0,
    reader   => 'get_stash',
    writer   => 'set_stash',
    default  => sub { return [] }
);

=pod

=head1 METHODS

=head2 get_stash

Returns the C<stash> attribute array reference.

=head2 set_stash

Sets the C<stash> attribute. Expects an array reference as parameter.

Beware that such call will complete remove all other data stored in the stash. To add single items, see C<push_stash> method.

=head2 push_stash

Pushes a new reference into the C<stash> attribute.

=cut

sub push_stash {

    my $self = shift;
    my $ref  = shift;

    push( @{ $self->get_stash() }, $ref );

    return 1;

}

=head2 shift_stash

Shifts the C<stash> attribute, removing the first item in the attribute and returning it.

If there is not other member to be shift, it will return undef.

=cut

sub shift_stash {

    my $self = shift;

    return shift( @{ $self->get_stash() } );

}

=head1 SEE ALSO

=over 2

=item *

L<Siebel::Srvrmgr::Daemon::Action>

=item *

L<MooseX::Singleton>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>.

This file is part of Siebel Monitoring Tools.

Siebel Monitoring Tools is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel Monitoring Tools is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Siebel Monitoring Tools.  If not, see L<http://www.gnu.org/licenses/>.

=cut

1;
