package Siebel::Srvrmgr::ListParser::Output;
use Moose;

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

no Moose;
__PACKAGE__->meta->make_immutable;

