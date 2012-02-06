package Siebel::Srvrmgr::ListParser::Output::Greetings;

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::Greetings - subclass that represents the initial information from a Siebel server when connected through srvrmgr program.

=head1 SYNOPSIS

See L<Siebel::Srvrmgr::ListParser::Output>.

=cut

use Moose;
use Siebel::Srvrmgr::Regexes;

extends 'Siebel::Srvrmgr::ListParser::Output';

=pod

=head1 DESCRIPTION

C<Siebel::Srvrmgr::ListParser::Output::Greetings> extends C<Siebel::Srvrmgr::ListParser::Output>.

Normally this class would be created by L<Siebel::Srvrmgr::ListParser::OutputFactory> C<create> static method. See the automated tests for examples of direct instatiation.

It is possible to recover some useful information from the object methods but most of it is simple copyrigh information.

Beware that the parse method is called automatically as soon as the object is created.

=head1 ATTRIBUTES

=head2 version

A string that represents the version of the Siebel enterprise where the connection was stablished. This is a read-only attribute.

=cut

has 'version' => (
    is     => 'ro',
    isa    => 'Str',
    reader => 'get_version',
    writer => '_set_version'
);

=pod

=head2 patch

A string that represents the patch version of the Siebel enterprise where the connection was stablished. This is a read-only attribute.

=cut

has 'patch' =>
  ( is => 'ro', isa => 'Int', reader => 'get_patch', writer => '_set_patch' );

=pod

=head2 copyright

A string that represents the copyright information of the Siebel enterprise where the connection was stablished. This is a read-only attribute.

=cut

has 'copyright' => (
    is     => 'ro',
    isa    => 'Str',
    reader => 'get_copyright',
    writer => '_set_copyright'
);

=pod

=head2 total_servers

A integer that represents the total number of servers configured in the enterprise where the connection was stablished. This is a read-only attribute.

=cut

has 'total_servers' => (
    is     => 'ro',
    isa    => 'Int',
    reader => 'get_total_servers',
    writer => '_set_total_servers'
);

=pod

=head2 total_connected 

A integer that represents the total number of servers available in the enterprise where the connection was stablished. This is a read-only attribute.

=cut

has 'total_connected' => (
    is     => 'ro',
    isa    => 'Int',
    reader => 'get_total_conn',
    writer => '_set_total_conn'
);

=pod

=head2 field_pattern

This attribute makes no sense for Greetings class, there it will always be equal C<undef>.

=head1 METHODS

See L<Siebel::Srvrmgr::ListParser::Output> class for inherited methods.

=head2 get_version

Returns a string as the value of version attribute.

=head2 get_patch

Returns a string as the value of patch attribute.

=head2 get_copyright

Returns a string as the value of copyright attribute.

=head2 get_total_servers

Returns a integer as the value of total_servers attribute.

=head2 get_total_conn

Returns a integer as the value of total_connected attribute.

=head2 parse

Parses the data available in the C<raw_data> attribute, setting the attribute C<data_parsed> at the end of process.

Also the attribute C<raw_data> has his reference changed to an empty array reference and the end of process.

=cut

sub parse {

    my $self = shift;

    my $data_ref = $self->get_raw_data();

    my $hello_regex = Siebel::Srvrmgr::Regexes::CONN_GREET;

    foreach my $line ( @{$data_ref} ) {

        chomp($line);
        next if $line eq '';

      SWITCH: {

            if ( $line =~ /$hello_regex/ ) {

#Siebel Enterprise Applications Siebel Server Manager, Version 7.5.3 [16157] LANG_INDEPENDENT
                my @words = split( /\s/, $line );

                $self->_set_version( $words[7] );
                $words[8] =~ tr/[]//d;
                $self->_set_patch( $words[8] );

                last SWITCH;

            }

            if ( $line =~ /^Copyright/ ) {

                #Copyright (c) 2001 Siebel Systems, Inc.  All rights reserved.

                $self->_set_copyright($line);

                last SWITCH;
            }

            if ( $line =~ /^Connected/ ) {

       #Connected to 1 server(s) out of a total of 1 server(s) in the enterprise
       #Connected to 2 server(s) out of a total of 2 server(s) in the enterprise
                my @words = split( /\s/, $line );

                $self->_set_total_servers( $words[9] );
                $self->_set_total_conn( $words[2] );

                last SWITCH;
            }

        }

    }

}

=pod

=head1 SEE ALSO

=over 2

=item *

L<Siebel::Srvrmgr::Regexes>

=item *

L<Siebel::Srvrmgr::ListParser::Output>

=back

=cut

no Moose;
__PACKAGE__->meta->make_immutable;

