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

=head1 CAVEATS

This class is not working due a limitation of L<MooseX::Storable>. See the corresponding test file for more information.

=head1 METHODS

=head2 do_parsed

It will check if the object given as parameter is a L<Siebel::Srvrmgr::ListParser::Output::ListParams> object. If true, it is serialized to the 
filesystem with C<nstore> and the function returns 1 in this case. If none is found it will return 0.

=cut

override 'do_parsed' => sub {

    my $self = shift;
    my $obj  = shift;

    if ( $obj->isa('Siebel::Srvrmgr::ListParser::Output::ListParams') ) {

        $obj->store( $self->get_dump_file() );

        return 1;

    }
    else {

        return 0;

    }

};

=pod

=head1 SEE ALSO

=over 2

=item *

L<Siebel::Srvrmgr::Daemon::Action>

=item *

L<Siebel::Srvrmgr::Daemon::Action::Serializable>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.org<E<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.org<E<gt>

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
along with Siebel Monitoring Tools.  If not, see <http://www.gnu.org/licenses/>.

=cut

__PACKAGE__->meta->make_immutable;
