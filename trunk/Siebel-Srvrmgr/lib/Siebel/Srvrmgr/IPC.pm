package Siebel::Srvrmgr::IPC;

=pod

=head1 NAME

Siebel::Srvrmgr::IPC - IPC functionality for Siebel::Srvrmgr classes.

=head1 SYNOPSIS

	use Siebel::Srvrmgr::IPC qw(safe_open3);

	my ( $pid, $write_h, $read_h, $error_h ) = safe_open3( \@params );

=head1 DESCRIPTION

This module exports a single function (C<safe_open3>) used for running a external program, reading it's STDOUT, STDERR and writing to STDIN by
using IPC.

This module is based on L<IPC::Open3::Callback> from Lucas Theisen (see SEE ALSO section).

=cut

require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(safe_open3);

use IPC::Open3;
use Symbol 'gensym';
use IO::Socket;
use Config;

=pod

=head1 EXPORTS

=head2 safe_open3

C<safe_open3> functions executes a "safe" version of L<IPC::Open3> that will execute additional processing required for using C<select> in Microsoft
Windows OS (if automatically detected). For other OS's, the default functionality of L<IPC::Open3> is used.

Expects as parameter an array reference with the external program to execute, including the arguments for it.

Returns (in this order):

=over

=item 1.

The PID of the child process executing the external program.

=item 2.

The writer handle to the child process.

=item 3.

The reader handle to the child process.

=item 4.

The error handle for the child process.

=back

=cut

sub safe_open3 {

    return ( $^O =~ /MSWin32/ )
      ? Siebel::Srvrmgr::IPC::_mswin_open3( $_[0] )
      : Siebel::Srvrmgr::IPC::_default_open3( $_[0] );

}

sub _mswin_open3 {

    my $cmd_ref = shift;

    my ( $inRead,  $inWrite )  = Siebel::Srvrmgr::IPC::_mswin_pipe();
    my ( $outRead, $outWrite ) = Siebel::Srvrmgr::IPC::_mswin_pipe();
    my ( $errRead, $errWrite ) = Siebel::Srvrmgr::IPC::_mswin_pipe();

    my $pid = open3(
        '>&' . fileno($inRead),
        '<&' . fileno($outWrite),
        '<&' . fileno($errWrite),
        @{$cmd_ref}
    );

    return ( $pid, $inWrite, $outRead, $errRead );
}

sub _mswin_pipe {

    my ( $read, $write ) =
      IO::Socket->socketpair( AF_UNIX, SOCK_STREAM, PF_UNSPEC );

# :WORKAROUND:14/08/2013 14:15:04:: shutdown the socket seems to disable the filehandle in Windows
    unless ( $Config{osname} eq 'MSWin32' ) {

        Siebel::Srvrmgr::IPC::_check_shutdown( 'read',
            $read->shutdown(SHUT_WR) );    # No more writing for reader
        Siebel::Srvrmgr::IPC::_check_shutdown( 'write',
            $write->shutdown(SHUT_RD) );    # No more reading for writer

    }

    return ( $read, $write );

}

sub _check_shutdown {

    my $which = shift;    # which handle name will be partly shutdown
    my $ret   = shift;

    unless ( defined($ret) ) {

        die "first argument of shutdown($which) is not a valid filehandle";

    }
    else {

        die "An error ocurred when trying shutdown($which): $!"
          if ( $ret == 0 );

    }

}

sub _default_open3 {

    my $cmd_ref = shift;

    my ( $inFh, $outFh, $errFh ) = ( gensym(), gensym(), gensym() );
    return ( open3( $inFh, $outFh, $errFh, @{$cmd_ref} ), $inFh, $outFh,
        $errFh );
}

=pod

=head1 SEE ALSO

=over

=item *

L<https://github.com/lucastheisen/ipc-open3-callback>

=item *

L<IPC::Open3>

=item *

L<IO::Socket>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.org<E<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

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

1;
