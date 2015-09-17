package Siebel::Srvrmgr::Log::Enterprise;

use Moose;
use namespace::autoclean;
use File::Copy;
use File::Temp qw(tempfile);
use Carp qw(cluck confess);
use String::BOM qw(strip_bom_from_string);

=pod

=head1 NAME

Siebel::Srvrmgr::Log::Enterprise - module to read a Siebel Enterprise log file

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 ATTRIBUTES

=head2 path

A string with the complete pathname to the Siebel Enterprise log file.

This attribute is required during object creation.

=cut

has path => ( is => 'ro', isa => 'Str', reader => 'get_path', required => 1 );

=head2 eol

A string identifying the character(s) used as end-of-line in the Siebel Enterprise log file is configured.

This attribute is read-only, this class will automatically try to define the field separator being used.

=cut

has eol => (
    is      => 'ro',
    isa     => 'Str',
    reader  => 'get_eol',
    writer  => '_set_eol',
    default => 0
);

=head2 fs

A string identifying the character(s) used to separate the fields ("fs" stands for "field separator") in the Siebel Enterprise log file is configured.

This attribute is read-only, this class will automatically try to define the EOL being used.

=cut

has fs => (
    is      => 'ro',
    isa     => 'Str',
    reader  => 'get_fs',
    writer  => '_set_fs',
    default => 0
);

=head2 fh

The file handle reference to the Siebel Enterprise log file, after was opened.

=cut

has fh =>
  ( is => 'ro', isa => 'FileHandle', reader => 'get_fh', writer => '_set_fh' );

=head1 SEE ALSO

=over

=item *

L<Moose>

=item *

L<Siebel::Srvrmgr::OS::Unix>

=back

=head1 METHODS

=head2 read

Reads the Siebel Enterprise log file, returning a iterator over the lines of the file.

The method will try to read the file as safely as possible, copying it to a temporary location before reading.

Several attributes will be defined during the file reading, automatically whenever it is possible. In some cases, if unable to
define those attributes, an exception will be raised.

=cut

sub read {

    my $self     = shift;
    my $template = __PACKAGE__ . '_XXXXXX';
    $template =~ s/\:{2}/_/g;
    my ( $fh, $filename ) = tempfile( $template, UNLINK => 1 );

    copy( $self->get_ent_log, $filename );

# :TODO:17-09-2015 14:24:21:: quite naive approach, should try to find EOL, close and open again the file
    my $header = <$fh>;
    $self->_check_header($header);
    $self->_set_fh($fh);

    local $/ = $self->get_eol();

    return sub {

        return <$fh>;

      }

}

sub DEMOLISH {

    my $self = shift;

    my $fh = $self->get_fh();

    if ( defined($fh) ) {

        close($fh);

    }

}

sub _check_header {

    my $self   = shift;
    my $header = strip_bom_from_string(shift);
    $self->_validate_archive($header);
    my @parts = split( /\s/, $header );
    $self->_define_eol( $parts[0] );
    $self->_define_fs( $parts[9], $parts[10] );

}

sub _define_fs {

    my $self             = shift;
    my $field_del_length = shift;
    my $field_delim      = shift;
    my $num;

    for my $i ( 1 .. 4 ) {

        my $temp = chop($field_del_length);
        if ( $temp != 0 ) {

            $num .= $temp;

        }
        else {

            last;

        }

    }

    confess "field delimiter unimplemented" if ( $num > 1 );

# converting hex number to the corresponding character as defined in ASCII table
    $self->_set_fs( chr( unpack( 's', pack 's', hex($field_delim) ) ) );

}

sub _validate_archive {

    my $self        = shift;
    my $header      = shift;
    my $curr_digest = md5_base64($header);

    if ( $self->get_archive()->has_digest() ) {

        unless ( $self->get_archive()->get_digest eq $curr_digest ) {

            # different log file
            $self->get_archive()->reset();
            $self->get_archive()->set_digest($curr_digest);

        }

    }
    else {

        $self->get_archive()->set_digest($curr_digest);

    }

}

sub _define_eol {

    my $self = shift;
    my $part = shift;
    my $eol  = substr $part, 1, 1;

  CASE: {

        if ( $eol eq '2' ) {

            $self->_set_eol("\015\012");
            last CASE;

        }

        if ( $eol eq '1' ) {

            $self->_set_eol("\012");
            last CASE;

        }

        if ( $eol eq '0' ) {

            $self->_set_eol("\015");
            last CASE;

        }
        else {

            confess "EOL is custom, don't know what to use!";

        }

    }

}

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

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
