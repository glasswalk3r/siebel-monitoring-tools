package Siebel::Srvrmgr::ListParser::Output::ListProcs::Proc;

use Moose;
use namespace::autoclean;
use MooseX::FollowPBP;

has server       => ( is => 'ro', isa => 'Str', required => 1 );
has comp_alias   => ( is => 'ro', isa => 'Str', required => 1 );
has pid          => ( is => 'ro', isa => 'Int', required => 1 );
has sisproc      => ( is => 'ro', isa => 'Int', required => 1 );
has normal_tasks => ( is => 'ro', isa => 'Int', required => 1 );
has sub_tasks    => ( is => 'ro', isa => 'Int', required => 1 );
has hidden_tasks => ( is => 'ro', isa => 'Int', required => 1 );
has vm_free      => ( is => 'ro', isa => 'Int', required => 1 );
has vm_used      => ( is => 'ro', isa => 'Int', required => 1 );
has pm_used      => ( is => 'ro', isa => 'Int', required => 1 );
has proc_enabled =>
  ( is => 'ro', isa => 'Bool', required => 1, reader => 'is_proc_enabled' );
has run_state => ( is => 'ro', isa => 'Str', required => 1 );
has sockets   => ( is => 'ro', isa => 'Int', required => 1 );

sub get_all_tasks {

    my $self = shift;

    return ( $self->get_normal_tasks() +
          $self->get_sub_tasks() + $self->get_hidden_tasks() );

}

__PACKAGE__->meta->make_immutable;
