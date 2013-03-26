package Siebel::Srvrmgr::Daemon::Action::LoadPreferences;

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon::Action::LoadPreferences - dummy subclass of Siebel::Srvrmgr::Daemon::Action to allow execution of load preferences command

=head1 SYNOPSIS

	use Siebel::Srvrmgr::Daemon::Action::LoadPreferences;

	my $action = Siebel::Srvrmgr::Daemon::Action::LoadPreferences->new(parser => Siebel::Srvrmgr::ListParser->new());

	$action->do(\@output);

=cut

use Moose;
use namespace::autoclean;

extends 'Siebel::Srvrmgr::Daemon::Action';

=head1 DESCRIPTION

The only usage for this class is to allow execution of C<load preferences> command by a L<Siebel::Srvrmgr::Daemon> object, allowing the execution
and parsing of the output of the command to be executed in the regular cycle of processing.

Executing C<load preferences> is particullary useful for setting the correct columns and sizing of output of commands like C<list comp>.

=head1 METHODS

=head2 do

C<do> method will not do much: it expects an array reference with the output of the command C<load preferences>. This content will be parsed
by L<Siebel::Srvrmgr::ListParser> object and as soon an L<Siebel::Srvrmgr::ListParser::Output::LoadPreferences> is found the method will return true (1).

If the LoadPreferences object is not found, the method will return false.

=cut

sub do {

    my $self   = shift;
    my $buffer = shift;

    $self->get_parser()->parse($buffer);

    my $tree = $self->get_parser()->get_parsed_tree();

    foreach my $obj ( @{$tree} ) {

        if ( $obj->isa('Siebel::Srvrmgr::ListParser::Output::LoadPreferences') )
        {

            return 1;

        }

    }    # end of foreach block

    return 0;

}

=pod

=head1 SEE ALSO

=over 3

=item *

L<Siebel::Srvrmgr::Daemon>

=item *

L<Siebel::Srvrmgr::Daemon::Action>

=item *

L<Siebel::Srvrmgr::ListParser::Output::LoadPreferences>

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
