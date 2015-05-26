package Siebel::Srvrmgr::Exporter::TermPulse;

use warnings;
use strict;

=head1 NAME

Siebel::Srvrmgr::Exporter::TermPulse - show pulsed progress bar in terminal

=cut

our $VERSION = "0.02";
our @ISA     = qw(Exporter);
our @EXPORT  = qw(pulse_start pulse_stop);

use Time::HiRes qw(usleep time);
require Exporter;

=head1 SYNOPSIS

    use Siebel::Srvrmgr::Exporter::TermPulse;
    pulse_start( name => 'Checking', rotate => 0, time => 1 ); # start the pulse
    sleep 3;
    pulse_stop()                                               # stop it

=head1 DESCRIPTION

This module was shamelessly copied from L<Term::Pulse>. Sorry, couldn't get my bug/patch approved. :-)

=head1 EXPORT

The following functions are exported by default.

=over

=item * 

pulse_start

=item *

pulse_stop

=back

=head1 FUNCTIONS

=head2 pulse_start()

Use this functions to start the pulse. Accept the following arguments:

=over

=item name

A simple message displayed before the pulse. The default value is 'Working'.

=item rotate

Boolean. Rotate the pulse if set to 1. Turn off by default.

=item time

Boolean. Display the elapsed time if set to 1. Turn off by default.

=item size

Set the pulse size. The default value is 16.

=back

=cut

my $pid = undef;
my $global_name;
my $global_start_time;
my @mark = qw(- \ | / - \ | /);
$| = 1;

sub pulse_start {

    my %args   = @_;
    my $name   = defined($args{name}) ? $args{name} : 'Working';
    my $rotate = defined($args{rotate}) ? $args{rotate} : 0;
    my $size   = defined($args{size}) ? $args{size} : 16;
    my $time   = defined($args{time}) ? $args{time} : 0;
    my $start  = time();

    $global_start_time = $start;
    $global_name       = $name;
    $pid               = fork();

    if ($pid) {    # parent
	
		$SIG{INT} = \&pulse_stop;
		$SIG{__DIE__} = \&pulse_stop;
        return $pid;

    }
    else {

		my $stop = 0;

        while (1) {

            # forward
            foreach my $index ( 1 .. $size ) {
                my $mark = $rotate ? $mark[ $index % 8 ] : q{=};
                printf "$name...[%s%s%s]", q{ } x ( $index - 1 ), $mark,
                  q{ } x ( $size - $index );
                printf " (%f sec elapsed)", ( time - $start ) if $time;
                printf "\r";
                usleep 200000;
            }

            # backward
            foreach my $index ( 1 .. $size ) {
                my $mark = $rotate ? $mark[ ( $index % 8 ) * -1 ] : q{=};
                printf "$name...[%s%s%s]", q{ } x ( $size - $index ), $mark,
                  q{ } x ( $index - 1 );
                printf " (%f sec elapsed)", ( time - $start ) if $time;
                printf "\r";
                usleep 200000;
            }
			
			last if($stop);
			
        }
    }
}

=head2 pulse_stop()

Stop the pulse and return elapsed time.

=cut

sub pulse_stop {

    if ( ( defined($pid) ) and ( $pid =~ /^\d+$/ ) ) {

        my $count = kill 'SIGZERO', $pid;

        if ( $count > 0 ) {

            $count = kill 'KILL', $pid;
            waitpid $pid, 0;
            $count = kill 'SIGZERO', $pid;

            if ($count) {

                warn "$pid is no more";

            }
            else {

                warn "child $pid is still running";

            }

            my $length = length($global_name);
            printf "$global_name%sDone%s\n", q{.} x ( 35 - $length ), q{ } x 43;

            my $elapsed_time = time - $global_start_time;
            return $elapsed_time;

        }

    }

}

=head1 KNOWN PROBLEMS

Not thread safe.

=head1 SEE ALSO

=over

=item *

L<Term::Pulse>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

L<Term::Pulse> was originally created by Yen-Liang Chen, E<lt>alec at cpan.comE<gt>

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

1;
