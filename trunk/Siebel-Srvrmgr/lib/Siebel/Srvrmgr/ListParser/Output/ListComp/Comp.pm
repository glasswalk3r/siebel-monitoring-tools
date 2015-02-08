package Siebel::Srvrmgr::ListParser::Output::ListComp::Comp;

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::ListComp::Comp - class that represents a Siebel component

=cut

use Moose;
use MooseX::FollowPBP;
use namespace::autoclean;

with 'Siebel::Srvrmgr::ListParser::Output::Duration';
with 'Siebel::Srvrmgr::ListParser::Output::ToString';

=pod

=head1 SYNOPSIS

    use Siebel::Srvrmgr::ListParser::Output::ListComp::Comp;

    # see Siebel::Srvrmgr::ListParser::Output::ListComp::Server for more details
    my $comp = Siebel::Srvrmgr::ListParser::Output::ListComp::Comp->new( {
                alias          => $data_ref->{CC_ALIAS},
                ct_alias       => $data_ref->{CT_ALIAS},
                cg_alias       => $data_ref->{CG_ALIAS},
                run_mode       => $data_ref->{CC_RUNMODE},
                disp_run_state => $data_ref->{CP_DISP_RUN_STATE},
                num_run_tasks  => $data_ref->{CP_NUM_RUN_TASKS},
                max_tasks      => $data_ref->{CP_MAX_TASKS},
                actv_mts_procs => $data_ref->{CP_ACTV_MTS_PROCS},
                max_mts_procs  => $data_ref->{CP_MAX_MTS_PROCS},
                start_datetime => $data_ref->{CP_START_TIME},
                end_datetime   => $data_ref->{CP_END_TIME},
                status         => $data_ref->{CP_STATUS},
                incarn_no      => $data_ref->{CC_INCARN_NO},
                desc_text      => $data_ref->{CC_DESC_TEXT}

    } );

    print 'NAME = ', $comp->get_name(), "\n";

=head1 DESCRIPTION

This class is meant to be used together with L<Siebel::Srvrmgr::ListParser::Output::Server> since a component is always associated with a Siebel server. This class is intended to make it 
easier to access and modify components as desired (for example, to export all components from one server to another changing some of their parameters).

This class uses the roles L<Siebel::Srvrmgr::ListParser::Output::Duration> and L<Siebel::Srvrmgr::ListParser::Output::ToString>.

=head1 ATTRIBUTES

Beware that some of the attributes of the component may reflect only the current state when the component data was recovered and are, by nature, dynamic. Some example are
the number of running tasks and state of the component.

=head2 alias

A string of the alias of the component.

This is a required attribute during object creation.

=cut

has alias => ( isa => 'Str', is => 'rw', required => 1 );

=pod

=head2 name

A string of the name of the component.

=cut

has name => ( isa => 'Str', is => 'rw', required => 1 );

=pod

=head2 ct_alias

A string of the component type alias.

=cut

has ct_alias => ( isa => 'Str', is => 'rw', required => 1 );

=pod

=head2 cg_alias

A string of the component group alias.

=cut

has cg_alias => ( isa => 'Str', is => 'rw', required => 1 );

=pod

=head2 run_mode

A string of the component run mode.

=cut

has run_mode => ( isa => 'Str', is => 'rw', required => 1 );

=pod

=head2 disp_run_state

A string of the component display run state.

This attribute is read-only.

=cut

has disp_run_state => ( isa => 'Str', is => 'ro', required => 1 );

=pod

=head2 num_run_tasks

An integer with the number of running tasks of the component.

This attribute is read-only.

=cut

has num_run_tasks => ( isa => 'Int', is => 'ro', required => 1 );

=pod

=head2 max_tasks

An integer with the maximum number of tasks the component will execute before restart itself.

=cut

has max_tasks => ( isa => 'Int', is => 'rw', required => 1 );

=pod

=head2 actv_mts_procs

An integer wit the active MTS processes running for the component.

This attribute is read-only.

=cut

has actv_mts_procs => ( isa => 'Int', is => 'ro', required => 1 );

=pod

=head2 max_mts_procs

An integer with the maximum number of MTS process that will run for the component.

=cut

has max_mts_procs => ( isa => 'Int', is => 'rw', required => 1 );

=pod

=head2 status

A string representing the status of the component.

This attribute is read-only.

=cut

has status => ( isa => 'Str', is => 'ro', required => 1 );

=pod

=head2 incarn_no

An integer with representing the component incarnation number.

This attribute is read-only.

=cut

has incarn_no => (
    isa      => 'Int',
    is       => 'ro',
    required => 1
);

=pod

=head2 desc_text

A string representing the description of the component.

=cut

has desc_text => ( isa => 'Str', is => 'rw', required => 1 );

=pod

=head1 METHODS

All attributes have the same methods name to access them. For setting them, just invoke the method name with the desirable value as parameter.

=head2 BUILD

The C<BUILD> method will create all attributes/methods based on the value of the C<data> attribute.

Once this operation is finished, the C<data> attribute is set to an empty hash reference.

=cut

sub BUILD {

    my $self = shift;
    $self->fix_endtime;

}

=pod

=head1 SEE ALSO

=over

=item *

L<Moose>

=item *

L<namespace::autoclean>

=item *

L<Siebel::Srvrmgr::ListParser::Output::Duration>

=item *

L<Siebel::Srvrmgr::ListParser::Output::ToString>

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

__PACKAGE__->meta->make_immutable;
