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

	my $comp = Siebel::Srvrmgr::ListParser::Output::ListComp::Comp->new({ data => \%data,  cc_lias => 'MyComp' });

	print 'ALIAS = ', $comp->cc_name(), "\n";

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

=head2 sv_name

A string of the name of the server where the component is associated.

=cut

has sv_name => ( isa => 'Str', is => 'rw' );

=pod

=head2 cc_alias

A string of the alias of the component.

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

=cut

has cp_disp_run_state => ( isa => 'Str', is => 'rw' );

=pod

=head2 cp_num_run_tasks

An integer with the number of running tasks of the component.

=cut

has cp_num_run_tasks => ( isa => 'Str', is => 'rw' );

=pod

=head2 cp_max_task

An integer with the maximum number of tasks the component will execute before restart itself.

=cut

has cp_max_task => ( isa => 'Str', is => 'rw' );

=pod

=head2 cp_actv_mts_procs

An integer wit the active MTS processes running for the component.

=cut

has cp_actv_mts_procs => ( isa => 'Str', is => 'rw' );

=pod

=head2 cp_max_mts_procs

An integer with the maximum number of MTS process that will run for the component.

=cut

has cp_max_mts_procs => ( isa => 'Str', is => 'rw' );

=pod

=head2 cp_start_time

An string representing the start time of the component.

=cut

has cp_start_time => ( isa => 'Str', is => 'rw' );

=pod

=head2 cp_end_time

An string representing the end time of the component.

=cut

has cp_end_time => ( isa => 'Str', is => 'rw' );

=pod

=head2 cp_status

A string representing the status of the component.

=cut

has cp_status => ( isa => 'Str', is => 'rw' );

=pod

=head2 cc_incarn_no

An integer with representing the component incarnation number.

=cut

has cc_incarn_no => ( isa => 'Str', is => 'rw' );

=pod

=head2 cc_desc_text

A string representing the description of the component.

=cut

has cc_desc_text => ( isa => 'Str', is => 'rw' );

=pod

=head1 METHODS

All attributes have the same methods name to access them. For setting them, just invoke the method name with the desirable value as parameter.

=head2 BUILD

=cut

sub BUILD {

    my $self = shift;

    foreach my $key ( keys( %{ $self->get_data() } ) ) {

        my $attrib = lc($key);

        $self->$attrib( $self->get_data()->{$key} );

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

=head2 get_attrib_val

Gets an attribute value. Expects as parameter the attribute name.

If the attribute does not exists for the component, an C<undef> value will be returned.

=cut

sub get_attrib_val {

    my $self   = shift;
    my $attrib = shift;

    if ( exists( $self->get_data()->{$attrib} ) ) {

        return $self->get_data()->{$attrib};

    }
    else {

        return undef;

    }

}

=pod

=head1 SEE ALSO

=over 2

=item *

L<Moose>

=item *

L<namespace::autoclean>

=back

=cut

__PACKAGE__->meta->make_immutable;
