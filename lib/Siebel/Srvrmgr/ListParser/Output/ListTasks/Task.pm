package Siebel::Srvrmgr::ListParser::Output::ListTasks::Task;
use Moose;
use namespace::autoclean;

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::ListServers - subclass to parse list tasks command

=head1 SYNOPSIS

See L<Siebel::Srvrmgr::ListParser::Output> for examples.

=head1 DESCRIPTION

This subclass of L<Siebel::Srvrmgr::ListParser::Output> parses the output of the command C<list tasks>.

=head1 ATTRIBUTES

=cut

has 'server_name'    => ( is => 'ro', isa => 'Str', required => 1 );
has 'comp_alias'     => ( is => 'ro', isa => 'Str', required => 1 );
has 'id'             => ( is => 'ro', isa => 'Int', required => 1 );
has 'pid'            => ( is => 'ro', isa => 'Int', required => 1 );
has 'run_mode'       => ( is => 'ro', isa => 'Str', required => 1 );
has 'comp_alias'     => ( is => 'ro', isa => 'Str', required => 1 );
has 'start'          => ( is => 'ro', isa => 'Str', required => 1 );
has 'end'            => ( is => 'ro', isa => 'Str', required => 1 );
has 'status'         => ( is => 'ro', isa => 'Str', required => 1 );
has 'cg_alias'       => ( is => 'ro', isa => 'Str', required => 1 );
has 'parent_id'      => ( is => 'ro', isa => 'Int', required => 0 );
has 'incarn_num'     => ( is => 'ro', isa => 'Int', required => 1 );
has 'label'          => ( is => 'ro', isa => 'Str', required => 0 );
has 'type'           => ( is => 'ro', isa => 'Str', required => 1 );
has 'last_ping_time' => ( is => 'ro', isa => 'Str', required => 0 );

=pod

=head1 METHODS

=head1 SEE ALSO

=over 2

=item *

L<Siebel::Srvrmgr::ListParser::Output>

=item *

L<Moose>

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
1;
