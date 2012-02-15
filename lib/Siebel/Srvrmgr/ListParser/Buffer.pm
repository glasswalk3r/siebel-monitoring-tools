package Siebel::Srvrmgr::ListParser::Buffer;

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Buffer - class to store output of commands

=cut

use Moose;
use namespace::autoclean;

=pod

=head1 SYNOPSIS

	my $buffer = Siebel::Srvrmgr::ListParser::Buffer->new(
		{
			type     => 'sometype',
			cmd_line => 'list something'
		}
	);

	$buffer->set_content( $cmd_output_line );

=head1 DESCRIPTION

This class is used by L<Siebel::Srvrmgr::ListParser> to store output read (between two commands) while is processing all the output.

=head1 ATTRIBUTES

=head2 type

String that identified which kind of output is being stored. This will be used by abstract factory classes to instantiate objects from 
L<Siebel::Srvrmgr::ListParser::Output> subclasses.

=cut

has 'type' => ( is => 'ro', isa => 'Str', required => 1, reader => 'get_type' );

=pod

=head2 cmd_line

String that contains the identified commands that generated the output.

=cut

has 'cmd_line' =>
  ( is => 'ro', isa => 'Str', required => 1, reader => 'get_cmd_line' );

=pod

=head2 content

An array reference with the output being stored. Each index is one line read stored from the output.

=cut

has 'content' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    reader  => 'get_content',
    writer  => '_set_content',
    default => sub { return [] }
);

=pod

=head1 METHODS

=head2 get_type

Returns the string stored in the attribute C<type>.

=head2 get_cmd_line

Returns the string stored in the attribute C<type>.

=head2 get_content

=head2 set_content

=cut

sub set_content {

    my $self  = shift;
    my $value = shift;

    if ( defined($value) ) {

        my $buffer_ref = $self->get_content();

        push( @{$buffer_ref}, $value );

        $self->_set_content($buffer_ref);

    }

}

__PACKAGE__->meta->make_immutable;
