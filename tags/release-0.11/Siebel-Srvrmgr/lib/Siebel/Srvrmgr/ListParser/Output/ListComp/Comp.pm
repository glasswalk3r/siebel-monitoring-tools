package Siebel::Srvrmgr::ListParser::Output::ListComp::Comp;

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::ListComp::Comp - class that represents a Siebel component

=cut

use Moose;
use namespace::autoclean;

=pod

=head1 SYNOPSIS

	use Siebel::Srvrmgr::ListParser::Output::ListComp::Comp;

	my $comp = Siebel::Srvrmgr::ListParser::Output::ListComp::Comp->new({ data => \%data,  cc_alias => 'MyComp' });

	print 'NAME = ', $comp->cc_name(), "\n";

	foreach my $param(@{$comp->get_params()}) {

		print $comp->get_param_val($param), "\n";
		
	}

=head1 DESCRIPTION

This class is meant to be used together with L<Siebel::Srvrmgr::ListParser::Output::Server> since a component is always associated with a Siebel server. It make it easy to
access and modify components as desired (for example, to export all components from one server to another changing some of their parameters).

=head1 ATTRIBUTES

Beware that some of the attributes of the component may reflect only the current state when the component data was recovered and are, by nature, dinamic. Some example are
the number of running tasks and state of the component.

=head2 data

A hash reference with the data of the component. The expected structure of the hash reference is the same one provided by the method C<get_comp> of the class
L<Siebel::Srvrmgr::ListParser::Output::Server>.

This is a required attribute during object creation.

=cut

has data => (
    isa      => 'HashRef',
    is       => 'ro',
    required => 1,
    reader   => 'get_data',
    writer   => '_set_data'
);

=pod

=head2 cc_alias

A string of the alias of the component.

This is a required attribute during object creation.

=cut

has cc_alias => ( isa => 'Str', is => 'rw', required => 1 );

=pod

=head2 cc_name

A string of the name of the component.

=cut

has cc_name => ( isa => 'Str', is => 'rw' );

=pod

=head2 ct_alias

A string of the component type alias.

=cut

has ct_alias => ( isa => 'Str', is => 'rw' );

=pod

=head2 ct_name

A string of the component type name.

=cut

has ct_name => ( isa => 'Str', is => 'rw' );

=pod

=head2 cg_alias

A string of the component group alias.

=cut

has cg_alias => ( isa => 'Str', is => 'rw' );

=pod

=head2 cc_runmode

A string of the component run mode.

=cut

has cc_runmode => ( isa => 'Str', is => 'rw' );

=pod

=head2 cp_disp_run_state

A string of the component display run state.

This attribute is read-only.

=cut

has cp_disp_run_state =>
  ( isa => 'Str', is => 'ro', writer => '_set_cp_disp_run_state' );

=pod

=head2 cp_num_run_tasks

An integer with the number of running tasks of the component.

This attribute is read-only.

=cut

has cp_num_run_tasks =>
  ( isa => 'Int', is => 'ro', writer => '_set_cp_num_run_tasks' );

=pod

=head2 cp_max_tasks

An integer with the maximum number of tasks the component will execute before restart itself.

=cut

has cp_max_tasks => ( isa => 'Int', is => 'rw' );

=pod

=head2 cp_actv_mts_procs

An integer wit the active MTS processes running for the component.

This attribute is read-only.

=cut

has cp_actv_mts_procs =>
  ( isa => 'Int', is => 'ro', writer => '_set_cp_actv_mts_procs' );

=pod

=head2 cp_max_mts_procs

An integer with the maximum number of MTS process that will run for the component.

=cut

has cp_max_mts_procs => ( isa => 'Int', is => 'rw' );

=pod

=head2 cp_start_time

An string representing the start time of the component.

This attribute is read-only.

=cut

has cp_start_time =>
  ( isa => 'Str', is => 'ro', writer => '_set_cp_start_time' );

=pod

=head2 cp_end_time

An string representing the end time of the component.

This attribute is read-only.

=cut

has cp_end_time => ( isa => 'Str', is => 'ro', writer => '_set_cp_end_time' );

=pod

=head2 cp_status

A string representing the status of the component.

This attribute is read-only.

=cut

has cp_status => ( isa => 'Str', is => 'ro', writer => '_set_cp_status' );

=pod

=head2 cc_incarn_no

An integer with representing the component incarnation number.

This attribute is read-only.

=cut

has cc_incarn_no => (
    isa    => 'Int',
    is     => 'ro',
    writer => '_set_cc_incarn_no'
);

=pod

=head2 cc_desc_text

A string representing the description of the component.

=cut

has cc_desc_text => ( isa => 'Str', is => 'rw' );

=pod

=head1 METHODS

All attributes have the same methods name to access them. For setting them, just invoke the method name with the desirable value as parameter.

=head2 BUILD

The C<BUILD> method will create all attributes/methods based on the value of the C<data> attribute.

Once this operation is finished, the C<data> attribute is set to an empty hash reference.

=cut

sub BUILD {

    my $self = shift;

    my @rw = qw(cc_name ct_alias cg_alias cc_runmode cp_max_tasks cc_desc_text);

    foreach my $attrib (@rw) {

        my $key = uc($attrib);

        $self->$attrib( $self->get_data()->{$key} )
          if ( exists( $self->get_data()->{$key} ) );

    }

    my @ro_str = qw(cp_disp_run_state cp_start_time cp_end_time cp_status);

    foreach my $attrib (@ro_str) {

        my $key = uc($attrib);

        my $method = "_set_$attrib";

        $self->$method( $self->get_data()->{$key} )
          if ( exists( $self->get_data()->{$key} ) );

    }

    my $key = uc('cp_max_mts_procs');

    if ( exists( $self->get_data()->{$key} ) ) {

        ( $self->get_data()->{$key} eq '' )
          ? $self->cp_max_mts_procs(0)
          : $self->cp_max_mts_procs( $self->get_data()->{$key} );

    }
    else {

        die "Cannot find $key in data attribute";

    }

    my @ro_int = qw(cp_num_run_tasks cp_actv_mts_procs cc_incarn_no);

    foreach my $attrib (@ro_int) {

        my $key = uc($attrib);

        my $method = "_set_$attrib";

        if ( exists( $self->get_data()->{$key} ) ) {

            ( $self->get_data()->{$key} eq '' )
              ? $self->$method(0)
              : $self->$method( $self->get_data()->{$key} );

        }
        else {

            die "Cannot find $key in data attribute";

        }
    }

    $self->_set_data( {} );

}

=pod

=head2 get_attribs

Returns an array reference with all the parameters names associated of the component object.

=cut

sub get_attribs {

    my $self = shift;

    return [ keys( %{ $self->get_data() } ) ];

}

=pod

=head1 SEE ALSO

=over 2

=item *

L<Moose>

=item *

L<namespace::autoclean>

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
