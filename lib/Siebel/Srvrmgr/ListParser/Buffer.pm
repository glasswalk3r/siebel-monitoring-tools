package Siebel::Srvrmgr::ListParser::Buffer;
use Moose;
use namespace::autoclean;

has 'type' => ( is => 'ro', isa => 'Str', required => 1, reader => 'get_type' );
has 'cmd_line' =>
  ( is => 'ro', isa => 'Str', required => 1, reader => 'get_cmd_line' );

has 'content' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    reader  => 'get_content',
    writer  => '_set_content',
    default => sub { return [] }
);

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
