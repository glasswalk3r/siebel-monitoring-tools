package Siebel::Srvrmgr::ListParser::Output::ListTasks::Task;
use Moose;
use MooseX::FollowPBP;
use namespace::autoclean;

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::ListTasks::Task - class to represent a Siebel task

=head1 SYNOPSIS

        my $task = $class->new(
            {
                server_name    => 'siebfoobar',
                comp_alias     => 'SRProc',
                id             => 5242888,
                pid            => 20503,
                run_mode       => 'Interactive',
                start          => '2013-04-22 15:32:28',
                end            => '2000-00-00 00:00:00',
                status         => 'Running',
                cg_alias       => 'SystemAux',
                parent_id      => 0,
                incarn_num     => 0,
                label          => '',
                type           => 'Normal',
                last_ping_time => ''
            }
        )

=head1 DESCRIPTION

An object that represents each task from a C<list tasks> command output from srvrmgr program.

=head1 ATTRIBUTES

All attributes are required unless documented that is not.

=head2 server_name

Name of the Siebel server where the task information was recovered.

=head2 comp_alias

The component alias corresponding to the task.

=head2 id

The task id.

=head2 pid

The corresponding process identifier from the running OS of the task (in fact, the PID from the related component process).

=head2 run_mode

Task run mode.

=head2 start

Task start time.

=head2 end

Task end time.

=head2 status

Task-reported status.

=head2 cg_alias

Component group alias.

=head2 parent_id

Parent task id. Not required.

=head2 incarn_num

Incarnation Number.

=head2 label

Task Label. Not required.

=head2 type

Task Type.

=head2 last_ping_time

Last ping time for task. Not required.

=cut

has 'server_name'    => ( is => 'ro', isa => 'Str', required => 1 );
has 'comp_alias'     => ( is => 'ro', isa => 'Str', required => 1 );
has 'id'             => ( is => 'ro', isa => 'Int', required => 1 );
has 'pid'            => ( is => 'ro', isa => 'Int', required => 1 );
has 'run_mode'       => ( is => 'ro', isa => 'Str', required => 1 );
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

All attributes have a getter named "get_<attribute name>".

Since all attributes are read-only there is no corresponding setter.

=head1 SEE ALSO

=over 3

=item *

L<Siebel::Srvrmgr::ListParser::Output::ListTasks>

=item *

L<Moose>

=item *

L<MooseX::FollowPBP>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.org<E<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.org<E<gt>

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
