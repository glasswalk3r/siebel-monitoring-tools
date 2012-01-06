package Siebel::Srvrmgr::ListParser::Output::ListComp::Comp;
use Moose;
use namespace::autoclean;

has data => (
    isa      => 'HashRef',
    is       => 'ro',
    required => 1,
    reader   => 'get_data',
    writer   => '_set_data'
);

has sv_name           => ( isa => 'Str', is => 'rw' );
has cc_alias          => ( isa => 'Str', is => 'rw' );
has cc_name           => ( isa => 'Str', is => 'rw' );
has ct_alias          => ( isa => 'Str', is => 'rw' );
has ct_name           => ( isa => 'Str', is => 'rw' );
has cg_alias          => ( isa => 'Str', is => 'rw' );
has cc_runmode        => ( isa => 'Str', is => 'rw' );
has cp_disp_run_state => ( isa => 'Str', is => 'rw' );
has cp_num_run_tasks  => ( isa => 'Str', is => 'rw' );
has cp_max_tasks      => ( isa => 'Str', is => 'rw' );
has cp_actv_mts_procs => ( isa => 'Str', is => 'rw' );
has cp_max_mts_procs  => ( isa => 'Str', is => 'rw' );
has cp_start_time     => ( isa => 'Str', is => 'rw' );
has cp_end_time       => ( isa => 'Str', is => 'rw' );
has cp_status         => ( isa => 'Str', is => 'rw' );
has cc_incarn_no      => ( isa => 'Str', is => 'rw' );
has cc_desc_text      => ( isa => 'Str', is => 'rw' );

sub BUILD {

    my $self = shift;

    foreach my $key ( keys( %{ $self->get_data() } ) ) {

        my $attrib = lc($key);

        $self->$attrib( $self->get_data()->{$key} );

    }

    $self->_set_data(undef);

}

sub get_attribs {

    my $self = shift;

    return [ keys( %{ $self->get_data() } ) ];

}

sub get_attrib {

    my $self   = shift;
    my $attrib = shift;

    if ( exists( $self->get_data()->{$attrib} ) ) {

        return $self->get_data()->{$attrib};

    }
    else {

        return undef;

    }

}

#sub create_cmd {
#
#    my $self = shift;
#
#    my $cmd =
#        'create component definition '
#      . $self->get_alias()
#      . ' for component type '
#      ;    # see "list comp types" and "list comp def", property
#    #to define the comp type alias
#
#	return $cmd;
#
#}

__PACKAGE__->meta->make_immutable;
