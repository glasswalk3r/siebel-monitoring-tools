package Siebel::Srvrmgr::ListParser::Output::Greetings;

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::Greetings - subclass that represents the initial information from a Siebel server when connected through srvrmgr program.

=head1 SYNOPSIS

See L<Siebel::Srvrmgr::ListParser::Output>.

=cut

use Moose;
use Siebel::Srvrmgr::Regexes;
use feature 'switch';

extends 'Siebel::Srvrmgr::ListParser::Output';

=pod

=head1 DESCRIPTION

C<Siebel::Srvrmgr::ListParser::Output::Greetings> extends C<Siebel::Srvrmgr::ListParser::Output>.

Normally this class would be created by L<Siebel::Srvrmgr::ListParser::OutputFactory> C<create> static method. See the automated tests for examples of direct 
instatiation.

It is possible to recover some useful information from the object methods but most of it is simple copyrigh information.

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

An array reference that represents the copyright information of the Siebel enterprise where the connection was stablished. This is a read-only attribute.

=cut

has 'copyright' => (
    is     => 'ro',
    isa    => 'ArrayRef[Str]',
    reader => 'get_copyright'
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

=head2 help

A string representing how to invoke online help within C<srvrmgr> program. This is a read-only attribute.

=cut

has 'help' => (
    is     => 'ro',
    isa    => 'Str',
    reader => 'get_help',
    writer => '_set_help'
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

This method overrides the superclass method since Siebel::Srvrmgr::ListParser::Output::Greetings simply does not follows the same sequence
as the other subclasses.

Parses the data available in the C<raw_data> attribute, setting the attribute C<data_parsed> at the end of process.

Also the attribute C<raw_data> has his reference changed to an empty array reference and the end of process.

=cut

override 'parse' => sub {

    my $self = shift;

    my $data_ref = $self->get_raw_data();

    my $hello_regex = Siebel::Srvrmgr::Regexes::CONN_GREET;

    my $is_copyright = 0;

    my %data_parsed;

    foreach my $line ( @{$data_ref} ) {

        chomp($line);

        given ($line) {

            when ('') {

                # do nothing
            }

            when (/$hello_regex/) {

#Siebel Enterprise Applications Siebel Server Manager, Version 7.5.3 [16157] LANG_INDEPENDENT
                my @words = split( /\s/, $line );

                $self->_set_version( $words[7] );
                $data_parsed{version} = $words[7];

                $words[8] =~ tr/[]//d;
                $self->_set_patch( $words[8] );
                $data_parsed{patch} = $words[8];

            }

            when (/^Copyright/) {

                #Copyright (c) 2001 Siebel Systems, Inc.  All rights reserved.
                $self->_set_copyright($line);
                $data_parsed{copyright} = $line;
                $is_copyright = 1;

            }

            when (/^Type\s\"help\"/) {

                $self->_set_help($line);
                $data_parsed{help} = $line;
                $is_copyright = 0;

            }

            when (/^Connected/) {

       #Connected to 1 server(s) out of a total of 1 server(s) in the enterprise
       #Connected to 2 server(s) out of a total of 2 server(s) in the enterprise
                my @words = split( /\s/, $line );

                $self->_set_total_servers( $words[9] );
                $self->_set_total_conn( $words[2] );
                $data_parsed{total_servers} = $words[9];
                $data_parsed{total_conn}    = $words[2];

            }

            when (/^[\w\(]+/) {

                $self->_set_copyright($line) if ($is_copyright);
                $data_parsed{copyright} = $line;

            }

            default {

                die 'Invalid data from line [' . $line . ']';

            }

        }

    }

    $self->set_data_parsed( \%data_parsed );

    return 1;

};

=pod

=head2 _set_copyright

"Private" method to set the copyright information.

=cut

sub _set_copyright {

    my $self = shift;
    my $line = shift;

    push( @{ $self->{copyright} }, $line );

    return 1;

}

# the methods below are overrided just because
# the parent class demands, but they are useless for Greetings (they are never invoked internally)
# since parse method is overrided as well
override '_set_header_regex' => sub {

    return qr/^.$/;

};

override '_parse_data' => sub {

    return 1;

};

sub BUILD {

    my $self = shift;

    $self->_set_fields_pattern('undefined');
    $self->set_header_cols( [] );

}

=pod

=head1 CAVEATS

Beware that the parse method is called automatically as soon as the object is created.

Greetings also does not follows the concept of fields from the superclass since it's output isn't tabular, so some related methods have "dummy" 
implementations since they make no sense at all to be invoked.

This is a good indicator that the superclass should be refactored to separate behaviour of output interpretation from tabular data expectation, so you might
expect this interface to be changed in future releases.

=head1 SEE ALSO

=over 2

=item *

L<Siebel::Srvrmgr::Regexes>

=item *

L<Siebel::Srvrmgr::ListParser::Output>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.org<E<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.org<E<gt>

This file is part of Siebel Monitoring Tools.

Siebel Monitoring Tools is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel Monitoring Tools is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Siebel Monitoring Tools.  If not, see <http://www.gnu.org/licenses/>.

=cut

__PACKAGE__->meta->make_immutable;
no Moose;
