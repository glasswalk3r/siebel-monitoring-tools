package Siebel::Srvrmgr::Daemon;

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon - class for interactive sessions with Siebel srvrmgr program

=head1 SYNOPSIS

    package MyDaemon;

	extends 'Siebel::Srvrmgr::Daemon';

=head1 DESCRIPTION

This class is used to execute the C<srvrmgr> program and execute commands through it.

The sessions are not "interactive" from the user point of view but the usage of this class enable the adoption of some logic to change how the commands will be executed or
even generate commands on the fly.

The logic behind this class is easy: you can submit a pair of command/action to the class. It will then connect to the server by executing C<srvrmgr>, submit the command to the server
and recover the output generated. The action will be executed having this output as parameter. Anything could be considered as an action, from simple storing the output to even generating
new commands to be executed in the server.

A command is any command supported from C<srvrmgr> program. An action can be any class but is obligatory to create a subclass of L<Siebel::Srvrmgr::Daemon::Action> base class. See the <commands>
attribute for details.

The object will create an loop to interact with the C<srvrmgr> program to execute the commands and actions as requested. This loop might be infinite, where the C<commands> attribute will be restarted when the
stack is finished.

The C<srvrmgr> program will be executed by using IPC: this means that this method should be portable. Once the connection is made (see the C<run> method) it will not be dropped after commands execution but it will
be done automatically when the instance of this class goes out of scope. The instance is also able to deal with C<INT> signal and close connection as appropriate: the class will first try to submit a C<exit> command
through C<srvrmgr> program and if it's not terminated automatically the PID will be ripped.

Logging of this class can be enabled by using L<Siebel::Srvrmgr> logging feature.

This module is based on L<IPC::Open3::Callback> from Lucas Theisen (see SEE ALSO section).

=cut

use Moose;
use namespace::autoclean;
use Siebel::Srvrmgr::Regexes qw(SIEBEL_ERROR);
use Siebel::Srvrmgr::Daemon::Command;
use POSIX;
use feature qw(switch);
use Siebel::Srvrmgr;
use Scalar::Util qw(weaken);
use Config;
use Carp qw(longmess);

our $SIG_INT   = 0;
our $SIG_PIPE  = 0;
our $SIG_ALARM = 0;

$SIG{INT}  = sub { $SIG_INT   = 1 };
$SIG{PIPE} = sub { $SIG_PIPE  = 1 };
$SIG{ALRM} = sub { $SIG_ALARM = 1 };

# :TODO      :19/08/2013 16:19:19:: enable Taint Mode

=pod

=head1 ATTRIBUTES

=head2 server

This is a string representing the servername where the instance should connect. This is a optional attribute during
object creation with the C<new> method.

Beware that the C<run> method will verify if the C<server> attribute has a defined value or not: if it has, the C<run>
method will try to connect to the Siebel Enterprise specifying the given Siebel Server. If not, the method will try to connect
to the Enterprise only, not specifying which Siebel Server to connect.

=cut

has server => (
    isa      => 'Str',
    is       => 'rw',
    required => 0,
    reader   => 'get_server',
    writer   => 'set_server'
);

=head2 gateway

This is a string representing the gateway where the instance should connect. This is a required attribute during
object creation with the C<new> method.

=cut

has gateway => (
    isa      => 'Str',
    is       => 'rw',
    required => 1,
    reader   => 'get_gateway',
    writer   => 'set_gateway'
);

=head2 enterprise

This is a string representing the enterprise where the instance should connect. This is a required attribute during
object creation with the C<new> method.

=cut

has enterprise => (
    isa      => 'Str',
    is       => 'rw',
    required => 1,
    reader   => 'get_enterprise',
    writer   => 'set_enterprise'
);

=head2 user

This is a string representing the login for authentication. This is a required attribute during
object creation with the C<new> method.

=cut

has user => (
    isa      => 'Str',
    is       => 'rw',
    required => 1,
    reader   => 'get_user',
    writer   => 'set_user'
);

=head2 password

This is a string representing the password for authentication. This is a required attribute during
object creation with the C<new> method.

=cut

has password => (
    isa      => 'Str',
    is       => 'rw',
    required => 1,
    reader   => 'get_password',
    writer   => 'set_password'
);

=head2 commands

An array reference containing one or more references of L<Siebel::Srvrmgr::Daemon::Commands> class.

The commands will be executed in the exactly order as given by the indexes in the array reference (as FIFO).

This is a required attribute during object creation with the C<new> method.

=cut

has commands => (
    isa      => 'ArrayRef[Siebel::Srvrmgr::Daemon::Command]',
    is       => 'rw',
    required => 1,
    reader   => 'get_commands',
    writer   => 'set_commands',
    trigger  => \&_setup_commands
);

=pod

=head2 bin

An string representing the full path to the C<srvrmgr> program in the filesystem.

This is a required attribute during object creation with the C<new> method.

=cut

has bin => (
    isa      => 'Str',
    is       => 'rw',
    required => 1,
    reader   => 'get_bin',
    writer   => 'set_bin'
);

=pod

=head2 is_infinite

An boolean defining if the interaction loop should be infinite or not.

=cut

has is_infinite => ( isa => 'Bool', is => 'ro', required => 1 );

=pod

=head2 alarm_timeout

The an integer value that will raise an ALARM signal generated by C<alarm>. The default value is 30 seconds.

Besides C<read_timeout>, this will raise an exception and exit the read loop from srvrmgr in cases were an output cannot be retrieved.

This attribute will be reset every time a read can be done from the STDOUT or STDERR from srvrmgr.

=cut

has alarm_timeout => (
    is      => 'Int',
    is      => 'rw',
    writer  => 'set_alarm',
    reader  => 'get_alarm',
    default => 30
);

=pod

=head2 use_perl

A boolean attribute used mostly for testing of this class.

If true, if will prepend the complete path of the Perl interpreter to the parameters before calling the C<srvrmgr> program (of course, srvrmgr must
be itself a Perl script).

It defaults to false.

=cut

has use_perl =>
  ( isa => 'Bool', is => 'ro', reader => 'use_perl', default => 0 );

=head2 lang_id

A string representing the LANG_ID parameter to connect to srvrmgr. If defaults to "ENU";

=cut

has lang_id => (
    isa     => 'Str',
    is      => 'rw',
    reader  => 'get_lang_id',
    writer  => 'set_lang_id',
    default => 'ENU'
);

=head2 child_runs

An integer representing the number of times the child object was used in C<run> invocations. This is reset to zero if a new child process is created.

=cut

has child_runs => (
    isa     => 'Int',
    is      => 'ro',
    reader  => 'get_child_runs',
    writer  => '_set_child_runs',
    default => 0
);

=head2 srvrmgr_prompt

An string representing the prompt recovered from srvrmgr program. The value of this attribute is set automatically during srvrmgr execution.

=cut

has srvrmgr_prompt =>
  ( isa => 'Str', is => 'ro', reader => 'get_prompt', writer => '_set_prompt' );

=head2 maximum_retries

The maximum times this class wil retry to launch a new process of srvrmgr if the previous one failed for any reason. This is intented to implement
robustness to the process.

=cut

has maximum_retries => (
    isa     => 'Int',
    is      => 'ro',
    reader  => 'get_max_retries',
    writer  => '_set_max_retries',
    default => 5
);

=head2 retries

The number of retries of launching a new srvrmgr process. If this value reaches the value defined for C<maximum_retries>, the instance of Siebel::Srvrmgr::Daemon
will quit execution returning an error code.

=cut

has retries => (
    isa     => 'Int',
    is      => 'ro',
    reader  => 'get_retries',
    writer  => '_set_retries',
    default => 0
);

=pod

=head1 METHODS

=head2 get_alarm

Returns the content of the C<alarm_timeout> attribute.

=head2 set_alarm

Sets the attribute C<alarm_timeout>. Expects an integer as parameter, in seconds.

=head2 clear_pid

Clears the defined PID associated with the child process that executes srvrmgr. This is usually associated with calling C<close_child>.

Beware that this is different then removing the child process or even C<undef> the attribute. This just controls a flag that the attribute C<child_pid>
is defined or not. See L<Moose> attributes for details.

=head2 has_pid

Returns true or false if the C<child_pid> is defined. Beware that this is different then checking if there is an integer associated with C<child_pid>
attribute: this method might return false even though the old PID associated with C<child_pid> is still available. See L<Moose> attributes for details.

=head2 get_prompt

Returns the content of the attribute C<srvrmgr_prompt>.

=head2 get_child_runs

Returns the value of the attribute C<child_runs>.

=head2 get_child_timeout

Returns the value of the attribute C<child_timeout>.

=head2 set_child_timeout

Sets the value of the attribute C<child_timeout>. Expects an integer as parameter, in seconds.

=head2 use_perl

Returns the content of the attribute C<use_perl>.

=head2 get_buffer_size

Returns the value of the attribute C<ipc_buffer_size>.

=head2 set_buffer_size

Sets the attribute C<ipc_buffer_size>. Expects an integer as parameter, multiple of 1024.

=head2 get_lang_id

Returns the value of the attribute C<lang_id>.

=head2 set_lang_id

Sets the attribute C<lang_id>. Expects a string as parameter.

=head2 get_server

Returns the content of C<server> attribute as a string.

=head2 set_server

Sets the attribute C<server>. Expects an string as parameter.

=head2 get_gateway

Returns the content of C<gateway> attribute as a string.

=head2 set_gateway

Sets the attribute C<gateway>. Expects a string as parameter.

=head2 get_enterprise

Returns the content of C<enterprise> attribute as a string.

=head2 set_enterprise

Sets the C<enterprise> attribute. Expects a string as parameter.

=head2 get_user

Returns the content of C<user> attribute as a string.

=head2 set_user

Sets the C<user> attribute. Expects a string as parameter.

=head2 get_password

Returns the content of C<password> attribute as a string.

=head2 set_password

Sets the C<password> attribute. Expects a string as parameter.

=head2 get_wait_time

Returns the content of the C<wait_time> attribute as a integer.

=head2 set_wait_time

Sets the attribute C<wait_time>. Expects a integer as parameter.

=head2 get_commands

Returns the content of the attribute C<commands>.

=head2 set_commands

Set the content of the attribute C<commands>. Expects an array reference as parameter.

=head2 get_bin

Returns the content of the C<bin> attribute.

=head2 set_bin

Sets the content of the C<bin> attribute. Expects a string as parameter.

=head2 get_write

Returns the file handle of STDIN from the process executing the C<srvrmgr> program based on the value of the attribute C<write_fh>.

=head2 get_read

Returns the file handle of STDOUT from the process executing the C<srvrmgr> program based on the value of the attribute C<read_fh>.

=head2 get_pid

Returns the content of C<pid> attribute as an integer.

=head2 is_infinite

Returns the content of the attribute C<is_infinite>, returning true or false depending on this value.

=head2 get_last_cmd

Returns the content of the attribute C<last_cmd> as a string.

=head2 get_cmd_stack

Returns the content of the attribute C<cmd_stack>.

=head2 get_params_stack

Returns the content of the attribute C<params_stack>.

=head2 reset_retries

Reset the retries of creating a new process of srvrmgr program, setting the attribute C<retries> to zero.

=cut

sub reset_retries {

    my $self = shift;

    $self->_set_retries(0);

    return 1;

}

sub _add_retry {

    my ( $self, $new, $old ) = @_;

    # if $old is undefined, this is the first call to run method
    unless ( defined($old) ) {

        return 0;

    }
    else {

        if ( $new != $old ) {

            $self->_set_retries( $self->get_retries() + 1 );
            return 1;

        }
        else {

            return 0;

        }

    }

}

=pod

=head2 shift_commands

Does a C<shift> in the C<commands> attribute.

Does not expects any parameter. Returns the C<shift>ed L<Siebel::Srvrmgr::Daemon::Command> instance or C<undef> if there is only B<one> 
command left (which is not C<shift>ed).

This method is useful specially if the Daemon will keep executing commands, but setup commands (like C<load preferences>) are not necessary to be executed
again.

=cut

sub shift_commands {

    my $self = shift;

    my $cmds_ref = $self->get_commands();

    if ( scalar( @{$cmds_ref} ) > 1 ) {

        my $shifted = shift( @{$cmds_ref} );
        $self->set_commands($cmds_ref);    # must trigger the attribute
        return $shifted;

    }
    else {

        return undef;

    }

}

=pod

=head2 run

This is the method used to execute commands in srvrmgr program and must be overrided by subclasses of Siebel::Srvrmgr::Daemon or an exception will
be generated.

=cut

sub run {

    confess
      'This method must be overrided by subclasses of Siebel::Srvrmgr::Daemon';

}

sub _define_params {

    my $self = shift;

    my @params = (
        $self->get_bin(),        '/e',
        $self->get_enterprise(), '/g',
        $self->get_gateway(),    '/u',
        $self->get_user(),       '/p',
        $self->get_password(),   '/l',
        $self->get_lang_id()

    );

    push( @params, '/s', $self->get_server() )
      if ( defined( $self->get_server() ) );

# :WORKAROUND:06/08/2013 21:05:32:: if a perlscript will be executed (like for automated testing of this distribution)
# then the perl interpreter must be part of the command path to avoid calling cmd.exe (in Microsoft Windows)
    unshift( @params, $Config{perlpath} ) if ( $self->use_perl() );

    return \@params;

}

sub _check_error {

    my $self   = shift;
    my $line   = shift;
    my $logger = shift;

    weaken($logger);

    # caught an error, until now all they are fatal
    $logger->warn( "Caught [$line]:" . longmess() );

    if ( $line =~ SIEBEL_ERROR ) {

        given ($line) {

            when (/^SBL-ADM-60070.*/) {

                $logger->warn(
                    'Trying to get additional information from next line')
                  if ( $logger->is_warn() );
                return 1;
            }

            when (/^SBL-ADM-02043.*/) {
                $logger->logdie('Could not find the Siebel Server')
            }

            when (/^SBL-ADM-02071.*/) {
                $logger->logdie('Could not find the Siebel Enterprise')
            }

            when (/^SBL-ADM-02049.*/) {
                $logger->logdie('Generic error')
            }

            when (/^SBL-ADM-02751.*/) {
                $logger->logdie('Unable to open file')
            }

            default {
                $logger->logdie('Unknown error, aborting execution')
            }

        }

    }
    else {

        $logger->warn(
            'Since this is not a Siebel error, I will try to keep running');

    }

}

=pod

=head2 DEMOLISH

This method is invoked before the object instance is destroyed. It does really few things like writting messages to the define configuration of
L<Log::Log4perl> logger. It will also log if ALRM, INT or PIPE signals were received.

Subclasses may want to C<override> the method "private" C<_my_cleanup> to do their properly laundry since the definition for this class is just C<return> true.

=cut

sub DEMOLISH {

    my $self = shift;

    my $logger = __PACKAGE__->gimme_logger();
    weaken($logger);

    $logger->info('Terminating daemon: preparing cleanup');

    $self->_my_cleanup();

    $logger->info('Cleanup is finished');

    if ( $logger->is_warn() ) {

        $logger->warn('Program termination was forced by ALRM signal')
          if ($SIG_ALARM);
        $logger->warn('Program termination was forced by INT signal')
          if ($SIG_INT);
        $logger->warn('Program termination was forced by PIPE signal')
          if ($SIG_PIPE);

    }

    $logger->info( ref($self) . ' says bye-bye' ) if ( $logger->is_info() );

}

=pod

=head2 gimme_logger

This method returns a L<Log::Log4perl::Logger> object as defined for L<Siebel::Srvrmgr> module.

It can be invoke both from a instance of Siebel::Srvrmgr::Daemon and the package itself.

=cut

sub gimme_logger {

    my $cfg = Siebel::Srvrmgr->logging_cfg();

    die "Could not start logging facilities"
      unless ( Log::Log4perl->init_once( \$cfg ) );

    return Log::Log4perl->get_logger('Siebel::Srvrmgr::Daemon');

}

sub _my_cleanup {

    return 1;

}

sub _setup_commands {

    confess
      'This method must be overrided by subclasses of Siebel::Srvrmgr::Daemon';

}

=pod

=head1 CAVEATS

This class is still considered experimental and should be used with care.

The C<srvrmgr> program uses buffering, which makes difficult to read the generated output as expected.

=head1 SEE ALSO

=over

=item *

L<Moose>

=item *

L<Siebel::Srvrmgr::Daemon::ActionFactory>

=item *

L<Siebel::Srvrmgr::ListParser>

=item *

L<Siebel::Srvrmgr::Regexes>

=item *

L<POSIX>

=item *

L<Siebel::Srvrmgr::Daemon::Command>

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

1;

