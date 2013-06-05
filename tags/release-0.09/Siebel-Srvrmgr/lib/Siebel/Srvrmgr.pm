package Siebel::Srvrmgr;
use warnings;
use strict;

our $VERSION = '0.09';

sub logging_cfg {

    my $cfg = undef;

    local $/;

    $cfg = <Siebel::Srvrmgr::DATA>;

    return $cfg;

}

1;

=pod

=head1 NAME

Siebel::Srvrmgr - utilities to be used with the Siebel srvrmgr program

=head1 DESCRIPTION

The distribution Siebel-Srvrmgr was created to define a set of tools to interact with the C<srvrmgr> program from Siebel.

It was started initially to create a parser for the project Siebel Monitoring Tools (L<http://code.google.com/p/siebel-monitoring-tools/>) and later was grown to a 
set of more generic functionality, thus making sense to be published at CPAN.

This package used to be only Pod, but since release 0.09 it has a logging feature. See logging_cfg for details.

=head1 CLASS METHODS

=head2 logging_cfg

Returns a string with the configuration to be used by a L<Log::Log4perl> instance.

The configuration of L<Log::Log4perl> is available after the C<__DATA__> code block of this package. Logging is disabled by default, but it can be enabled by
only commenting the line:

    log4perl.threshold = OFF

with the default "#" Perl comment character.

Logging is quite flexible (see L<Log::Log4Perl> for details) but the default configuration uses only FATAL level printing messages to STDOUT.

=head1 SEE ALSO

The classes below might give you a introduction of the available classes and features.

=over 2

=item *

L<Siebel::Srvrmgr::Daemon>

=item *

L<Siebel::Srvrmgr::ListParser>

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

__DATA__
log4perl.threshold = OFF
log4perl.logger.Siebel.Srvrmgr.Daemon=FATAL, A1
log4perl.appender.A1=Log::Dispatch::Screen
log4perl.appender.A1.stderr=0
log4perl.appender.A1.layout=Log::Log4perl::Layout::PatternLayout
log4perl.appender.A1.layout.ConversionPattern=%d %p> %F{1}:%L %M - %m%n
log4perl.logger.Siebel.Srvrmgr.ListParser=FATAL, A1
