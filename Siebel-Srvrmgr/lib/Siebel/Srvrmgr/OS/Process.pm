package Siebel::Srvrmgr::OS::Process;

use Moose;
use MooseX::FollowPBP;
use namespace::autoclean;
use Set::Tiny;

has pid        => ( is => 'ro', isa => 'Int', required => 1 );
has fname      => ( is => 'ro', isa => 'Str', required => 1 );
has pctcpu     => ( is => 'ro', isa => 'Num', required => 1 );
has pctmem     => ( is => 'ro', isa => 'Num', required => 1 );
has rss        => ( is => 'ro', isa => 'Int', required => 1 );
has vsz        => ( is => 'ro', isa => 'Int', required => 1 );
has comp_alias => ( is => 'rw', isa => 'Str', required => 0 );

sub _build_set {

    return Set::Tiny->new(
        'siebmtsh', 'siebmtshmw', 'siebproc', 'siebprocmw',
        'siebsess', 'siebsh',     'siebshmw'
    );

}

sub BUILD {

    my $self = shift;
    my $set  = $self->_build_set();

    if ( $set->has( $self->get_fname ) ) {

        $self->set_comp_alias('unknown');

    }
    else {

        $self->set_comp_alias('N/A');

    }

}

__PACKAGE__->meta->make_immutable;
