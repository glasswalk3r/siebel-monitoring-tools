package Siebel::Srvrmgr::ListParser::Output;

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output - base class of output classes

=head1 SYNOPSIS

=cut

use Moose;

use MooseX::Storage;
use namespace::autoclean;

with Storage( io => 'StorableFile' );

has 'data_type' =>
  ( is => 'ro', isa => 'Str', reader => 'get_data_type', required => 1 );

has 'raw_data' => (
    is       => 'rw',
    isa      => 'ArrayRef',
    reader   => 'get_raw_data',
    writer   => 'set_raw_data',
    required => 1
);
has 'data_parsed' => (
    is     => 'rw',
    isa    => 'HashRef',
    reader => 'get_data_parsed',
    writer => 'set_data_parsed'
);
has 'cmd_line' =>
  ( isa => 'Str', is => 'ro', reader => 'get_cmd_line', required => 1 );

=pod

=head2 fields_pattern

When starting processing the output of C<list comp> command, the header is read and the size of each column is taken
from the header of each column. With this information a pattern is build to match each value foreach line read. This 
attribute will hold the string that describes this pattern (that latter will be used with the C<unpack()> builtin function).

Therefore is B<really> important that the header of C<srvrmgr> program is not removed or the parser will not work properly
and probably an exception will be raised by it.

=cut

has 'fields_pattern' => (
    is      => 'ro',
    isa     => 'Str',
    reader  => 'get_fields_pattern',
    writer  => '_set_fields_pattern',
    default => sub { undef }
);

sub parse {

    die 'parse method must be overrided by subclasses of ' . __PACKAGE__;

}

no Moose;
__PACKAGE__->meta->make_immutable;

