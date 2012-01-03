package Siebel::Srvrmgr::Daemon::Condition;

=pod
=head1 NAME

Siebel::Srvrmgr::Daemon::Condition - object that checks which conditions should keep a Siebel::Srvrmgr::Daemon running

=head1 SYNOPSIS

    my $condition = Siebel::Srvrmgr::Daemon::Condition(
        {
            is_infinite    => $self->is_infinite(),
            total_commands => scalar( @{ $self->commands() } )
        }
    );

=cut

use warnings;
use strict;
use Moose;
use namespace::autoclean;

has is_infinite    => ( isa => 'Bool', is => 'ro', required => 1 );
has total_commands => ( isa => 'Int',  is => 'ro', required => 1 );
has cmd_counter    => (
    isa      => 'Int',
    is       => 'ro',
    required => 1,
    writer   => '_set_cmd_counter',
    reader   => 'get_cmd_counter',
    default  => 0
);

sub check {

    my $self = shift;

    if ( $self->is_infinite() and ( $self->total_commands() > 1 ) ) {

        if ( ( $self->get_cmd_counter() + 1 ) <=
            ( $self->total_commands() - 1 ) )
        {

            $self->add_cmd_counter();
            return 1;

        }
        else {

            $self->reset_cmd_counter();

            return 1;

        }

    }
    elsif ( $self->is_infinite() ) {

        return 1;

    }
    else {

        return 0;

    }

}

sub add_cmd_counter {

    my $self = shift;

    if ( ( $self->get_cmd_counter() + 1 ) <= ( $self->total_commands() - 1 ) ) {

        $self->_set_cmd_counter( $self->get_cmd_counter() + 1 );

    }
    else {

        die "Can't increment counter because maximum of commands is "
          . $self->total_commands() . "\n";

    }

}

sub reset_cmd_counter {

    my $self = shift;

    $self->_set_cmd_counter(0);

}

__PACKAGE__->meta->make_immutable;
