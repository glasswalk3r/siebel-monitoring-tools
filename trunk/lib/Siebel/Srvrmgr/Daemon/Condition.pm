package Siebel::Srvrmgr::Daemon::Condition;

=pod
=head1 NAME

Siebel::Srvrmgr::Daemon::Condition - object that checks which conditions should keep a Siebel::Srvrmgr::Daemon running

=head1 SYNOPSIS

    my $condition = Siebel::Srvrmgr::Daemon::Condition(
        {
            is_infinite    => $self->is_infinite(),
            max_cmd_idx => scalar( @{ $self->commands() } )
        }
    );

=cut

use warnings;
use strict;
use Moose;
use namespace::autoclean;

has is_infinite => ( isa => 'Bool', is => 'ro', required => 1 );
has max_cmd_idx =>
  ( isa => 'Int', is => 'ro', required => 0, writer => '_set_max_cmd_idx' );
has total_commands =>
  ( isa => 'Int', is => 'ro', required => 1, writer => '_set_total_commands' );
has cmd_counter => (
    isa      => 'Int',
    is       => 'ro',
    required => 1,
    writer   => '_set_cmd_counter',
    reader   => 'get_cmd_counter',
    default  => 0
);
has output_used => ( isa => 'Bool', is => 'rw', default => 0 );
has cmd_sent    => ( isa => 'Bool', is => 'rw', default => 0 );

sub BUILD {

    my $self = shift;

    $self->_set_max_cmd_idx( ( $self->total_commands() ) - 1 );

}

sub reduce_total_cmd {

    my $self = shift;

    $self->_set_total_commands( $self->total_commands() - 1 );

}

sub check {

    my $self = shift;

    if ( $self->is_infinite() ) {

        if ( $self->total_commands() > 1 ) {

            if ( ( $self->get_cmd_counter() + 1 ) <= $self->max_cmd_idx() ) {

                $self->add_cmd_counter();
                return 1;

            }
            else {

                $self->reset_cmd_counter();
                return 1;

            }

        }
        else {

            return 1;

        }

    }
    elsif ( ( $self->get_cmd_counter() == $self->max_cmd_idx() )
        and $self->output_used() )
    {

        return 0;

    }
    elsif ( $self->total_commands() > 0 ) {

        # if at least one command to execute
        if ( $self->total_commands() == 1 ) {

            $self->reduce_total_cmd();
            return 1;

            # or there are more commands to execute
        }
        elsif ( ( $self->total_commands() > 1 )
            and ( $self->get_cmd_counter() <= ( $self->max_cmd_idx() ) ) )
        {

            return 1;

        }
        else {

            return 0;

        }

    }
    else {

        return 0;

    }

}

sub add_cmd_counter {

    my $self = shift;

    if ( ( $self->get_cmd_counter() + 1 ) <= ( $self->max_cmd_idx() ) ) {

        $self->_set_cmd_counter( $self->get_cmd_counter() + 1 )
          if ( $self->output_used() );

		  return 1;

    }
    else {

        warn "Can't increment counter because maximum index of command is "
          . $self->max_cmd_idx() . "\n";


		  return 0;

    }

}

sub reset_cmd_counter {

    my $self = shift;

    $self->_set_cmd_counter(0);

}

__PACKAGE__->meta->make_immutable;
