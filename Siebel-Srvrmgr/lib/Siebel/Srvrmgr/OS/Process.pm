package Siebel::Srvrmgr::OS::Process;

use Moose;
use MooseX::FollowPBP;
use namespace::autoclean;
use Set::Tiny;

=pod

=head1 NAME

Siebel::Srvrmgr::OS::Process - class to represents a operational system process of Siebel

=head2 DESCRIPTION

This class holds information regarding a operational system process that is (hopefully) related to a running Siebel Server.

=head1 ATTRIBUTES

Except for the C<comp_alias> attribute, all attributes are read-only and required during object instantiation.

=head2 pid

A integer representing the process identification.

=cut

has pid => ( is => 'ro', isa => 'Int', required => 1 );

=head2 fname

A string of the program filename

=cut

has fname => ( is => 'ro', isa => 'Str', required => 1 );

=head2 pctcpu

A float of the percentage of CPU the process was using.

=cut

has pctcpu => ( is => 'ro', isa => 'Num', required => 1 );

=head2 pctmem

A float of the percentage of memory the process was using.

=cut

has pctmem => ( is => 'ro', isa => 'Num', required => 1 );

=head2 rss

For Unix-like OS only: the RSS of the process.

=cut

has rss => ( is => 'ro', isa => 'Int', required => 1 );

=head2 vsz

For Unix-like OS only: the VSZ used by the process.

=cut

has vsz => ( is => 'ro', isa => 'Int', required => 1 );

=head2 comp_alias

A string of the component alias associated with the process.

When the process is not directly related to Siebel (for example, a web server that servers SWSE), the value will be automatically defined
to "/NA".

When the PID is not identified in the source (a class that implements L<Siebel::Srvrmgr::Comps_source>), the default value will be "unknown".

=cut

has comp_alias => ( is => 'rw', isa => 'Str', required => 0 );

sub _build_set {

    return Set::Tiny->new(
        'siebmtsh', 'siebmtshmw', 'siebproc', 'siebprocmw',
        'siebsess', 'siebsh',     'siebshmw'
    );

}

=head1 METHODS

All attributes have their "getter" methods as defined in the Perl Best Practices book.

The C<comp_alias> attribute also have the "setter" method.

=head2 BUILD

This method is invoked automatically when a object is created.

It takes care of setting proper initialization of the C<comp_alias> attribute.

=cut

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
