package Siebel::Srvrmgr::Daemon;

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon - class for interactive sessions with Siebel srvrmgr program

=head1 SYNOPSIS

    use Siebel::Srvrmgr::Daemon;

    my $daemon = Siebel::Srvrmgr::Daemon->new(
        {
            server      => 'servername',
            gateway     => 'gateway',
            enterprise  => 'enterprise',
            user        => 'user',
            password    => 'password',
            bin         => 'c:\\siebel\\client\\bin\\srvrmgr.exe',
            is_infinite => 1,
			commands    => [
			        Siebel::Srvrmgr::Daemon::Command->new(
                        command => 'load preferences',
                        action  => 'LoadPreferences'
                    ),
                    Siebel::Srvrmgr::Daemon::Command->new(
                        command => 'list comp type',
                        action  => 'ListCompTypes',
                        params  => [$comp_types_file]
                    ),
                    Siebel::Srvrmgr::Daemon::Command->new(
                        command => 'list comp',
                        action  => 'ListComps',
                        params  => [$comps_file]
                    ),
                    Siebel::Srvrmgr::Daemon::Command->new(
                        command => 'list comp def',
                        action  => 'ListCompDef',
                        params  => [$comps_defs_file]
                    )
                ]
        }
    );


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
use Siebel::Srvrmgr::Daemon::Condition;
use Siebel::Srvrmgr::Daemon::ActionFactory;
use Siebel::Srvrmgr::ListParser;
use Siebel::Srvrmgr::Regexes
  qw(SRVRMGR_PROMPT LOAD_PREF_RESP SIEBEL_ERROR ROWS_RETURNED);
use Siebel::Srvrmgr::Daemon::Command;
use POSIX ":sys_wait_h";
use feature qw(say switch);
use Log::Log4perl;
use Siebel::Srvrmgr;
use Data::Dumper;
use Scalar::Util qw(weaken openhandle);
use Config;
use Siebel::Srvrmgr::IPC;
use IO::Select;
use Encode;
use Carp qw(longmess);

$SIG{INT}  = \&_term_INT;
$SIG{PIPE} = \&_term_PIPE;
$SIG{ALRM} = \&_term_ALARM;

our $SIG_INT   = 0;
our $SIG_PIPE  = 0;
our $SIG_ALARM = 0;

 # :TODO      :16/08/2013 19:02:24:: add statistics for daemon, like number of runs and average of used buffer for each command

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

=head2 wait_time

This represent the time that the instance should wait after submitting a command to the server.

The time value is an integer in seconds. The default value is 1 second.

This should help with servers that are slow to giving a reply after a command submitted and avoid errors while
trying to process generated output.

=cut

has wait_time => (
    isa     => 'Int',
    is      => 'rw',
    default => 1,
    reader  => 'get_wait_time',
    writer  => 'set_wait_time'
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

=head2 write_fh

A filehandle reference to the C<srvrmgr> STDIN. This is a read-only attribute.

=cut

has write_fh => (
    isa    => 'FileHandle',
    is     => 'ro',
    writer => '_set_write',
    reader => 'get_write'
);

=pod

=head2 read_fh

A filehandle reference to the C<srvrmgr> STDOUT.

This is a read-only attribute.

=cut

has read_fh => (
    isa    => 'FileHandle',
    is     => 'ro',
    writer => '_set_read',
    reader => 'get_read'
);

=pod

=head2 error_fh

A filehandle reference to the C<srvrmgr> STDERR.

This is a read-only attribute.

=cut

has error_fh => (
    isa    => 'FileHandle',
    is     => 'ro',
    writer => '_set_error',
    reader => 'get_error'
);

=pod

=head2 read_timeout

The read_timeout to read from child process handlers. It defaults to 15.

=cut

has read_timeout => (
    isa     => 'Int',
    is      => 'rw',
    writer  => 'set_read_timeout',
    reader  => 'get_read_timeout',
    default => 10
);

=pod

=head2 child_pid

An integer presenting the process id (PID) of the process created by the OS when the C<srvrmgr> program is executed.

This is a read-only attribute.

=cut

has child_pid => (
    isa       => 'Int',
    is        => 'ro',
    writer    => '_set_pid',
    reader    => 'get_pid',
    clearer   => 'clear_pid',
    predicate => 'has_pid',
    trigger   => \&_add_retry
);

=pod

=head2 is_infinite

An boolean defining if the interaction loop should be infinite or not.

=cut

has is_infinite => ( isa => 'Bool', is => 'ro', required => 1 );

=pod

=head2 last_exec_cmd

This is a string representing the last command submitted to the C<srvrmgr> program. The default value for it is an
empty string (meaning that no command was submitted yet).

=cut

has last_exec_cmd => (
    isa     => 'Str',
    is      => 'ro',
    default => '',
    reader  => 'get_last_cmd',
    writer  => '_set_last_cmd'
);

=pod

=head2 cmd_stack

This is an array reference with the stack of commands to be executed. It is maintained automatically by the class, so the attribute is read-only.

=cut

has cmd_stack => (
    isa    => 'ArrayRef',
    is     => 'ro',
    writer => '_set_cmd_stack',
    reader => 'get_cmd_stack'
);

=pod

=head2 params_stack

This is an array reference with the stack of params passed to the respective class. It is maintained automatically by the class so the attribute is read-only.

=cut

has params_stack => (
    isa    => 'ArrayRef',
    is     => 'ro',
    writer => '_set_params_stack',
    reader => 'get_params_stack'
);

=pod

=head2 action_stack

This is an array reference with the stack of actions to be taken. It is maintained automatically by the class, so the attribute is read-only.

=cut

has action_stack => (
    isa    => 'ArrayRef',
    is     => 'ro',
    writer => '_set_action_stack',
    reader => 'get_action_stack'
);

=pod

=head2 child_timeout

The time, in seconds, to wait after submitting a C<quit> command to srvrmgr before trying to kill the Pid associated with it.

It defaults to one second.

=cut

has child_timeout => (
    isa     => 'Int',
    is      => 'rw',
    writer  => 'set_child_timeout',
    reader  => 'get_child_timeout',
    default => 1
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

=head2 ipc_buffer_size

A integer describing the size of the buffer used to read output from srvrmgr program by using IPC.

It defaults to 5120 bytes, but it can be adjusted to improve performance (lowering CPU usage by increasing memory utilization).

=cut

has ipc_buffer_size => (
    isa     => 'Int',
    is      => 'rw',
    reader  => 'get_buffer_size',
    writer  => 'set_buffer_size',
    default => 5120
);

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

has maximum_retries => (
    isa     => 'Int',
    is      => 'ro',
    reader  => 'get_max_retries',
    writer  => '_set_max_retries',
    default => 5
);

has retries => (
    isa     => 'Int',
    is      => 'ro',
    reader  => 'get_retries',
    writer  => '_set_retries',
    default => 0
);

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

=head1 METHODS

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

=head2 _setup_commands

"Private" method: populates the attributes C<cmd_stack>, C<action_stack> and C<params_stack> depending on the values available on the C<commands> attribute.

This method is internally invoked everytime the C<commands> attribute is changed.

=cut

sub _setup_commands {

    my $self     = shift;
    my $cmds_ref = $self->get_commands();

    my @cmd;
    my @actions;
    my @params;

    foreach my $cmd ( @{$cmds_ref} ) {

        push( @cmd,     $cmd->get_command() );
        push( @actions, $cmd->get_action() );
        push( @params,  $cmd->get_params() );

    }

    $self->_set_cmd_stack( \@cmd );
    $self->_set_action_stack( \@actions );
    $self->_set_params_stack( \@params );

    return 1;

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

This method will try to connect to a Siebel Enterprise through C<srvrmgr> program (if it is the first time the method is invoke) or reuse an already open
connection to submit the commands and respective actions defined during object creation. The path to the program is check and if it does not exists the 
method will issue an warning message and immediatly returns false.

Those operations will be executed in a loop as long the C<check> method from the class L<Siebel::Srvrmgr::Daemon::Condition> returns true.

Beware that Siebel::Srvrmgr::Daemon uses a B<single instance> of a L<Siebel::Srvrmgr::ListParser> class to process the parsing requests, so it is not possible
to execute L<Siebel::Srvrmgr::Daemon::Command> instances in parallel.

=cut

# :WORKAROUND:10/05/2013 15:23:52:: using a state machine with FSA::Rules is difficult here because it is necessary to loop over output from
# srvrmgr but the program will hang if there is no output left to be read from srvrmgr.

sub run {

    my $self = shift;

    my $logger;
    my $temp;
    my $ignore_output = 0;

    my ( $read_h, $write_h, $error_h );

# :WORKAROUND:31/07/2013 14:42:33:: must initialize the Log::Log4perl after forking the srvrmgr to avoid sharing filehandles
    unless ( $self->has_pid() ) {

        $logger = $self->_create_child();

        unless ( ( defined($logger) ) and ( ref($logger) ) ) {

            die( $self->get_bin()
                  . ' returned un unrecoverable error, aborting execution' )

        }
        else {

            weaken($logger);

        }

    }
    else {

        $logger = __PACKAGE__->_gimme_logger();
        weaken($logger);
        $logger->info( 'Reusing PID ', $self->get_pid() )
          if ( $logger->is_debug() );
        $ignore_output = 1;

    }

    $logger->info('Starting run method');

# :WARNING:28/06/2011 19:47:26:: reading the output is hanging without a dummy input
#syswrite $self->get_write(), "\n";

    my @input_buffer;

# :TODO      :06/08/2013 19:13:47:: create condition as a hidden attribute of this class
    my $condition = Siebel::Srvrmgr::Daemon::Condition->new(
        {
            is_infinite    => $self->is_infinite(),
            total_commands => scalar( @{ $self->get_commands() } ),
            cmd_sent       => 0
        }
    );

    my $parser = Siebel::Srvrmgr::ListParser->new();

    my $select = IO::Select->new();
    $select->add( $self->get_read(), $self->get_error() );

    # to keep data from both handles while looping over them
    my %data;

    foreach my $fh ( $self->get_read(), $self->get_error() ) {

        my $fh_name  = fileno($fh);
        my $fh_bytes = $fh_name . '_bytes';

        $data{$fh_name}  = undef;
        $data{$fh_bytes} = 0;

    }

    if ( $logger->is_debug() ) {

        if ( openhandle( $self->get_read() ) ) {

            $logger->debug( 'fileno of child read handle = '
                  . fileno( $self->get_read() ) );

        }
        else {

            $logger->debug('read_fh is not available');

        }

        if ( openhandle( $self->get_error() ) ) {

            $logger->debug( 'fileno of child error handle = '
                  . fileno( $self->get_error() ) )

        }
        else {

            $logger->debug('error_fh is not available');

        }
        $logger->debug( 'Setting '
              . $self->get_read_timeout()
              . ' seconds for read srvrmgr output time out' );

    }

    do {

        exit if ($SIG_INT);

      READ:
        while ( my @ready = $select->can_read( $self->get_read_timeout() ) ) {

            foreach my $fh (@ready) {

                my $fh_name  = fileno($fh);
                my $fh_bytes = $fh_name . '_bytes';

                if ( $logger->is_debug() ) {

                    $logger->debug( 'Reading filehandle ' . fileno($fh) );
                    my $assert = 'Input record separator is ';

                    given ($/) {

                        when ( $/ eq "\015" ) {
                            $logger->debug( $assert . 'CR' )
                        }
                        when ( $/ eq "\015\012" ) {
                            $logger->debug( $assert . 'CRLF' )
                        }
                        when ( $/ eq "\012" ) {
                            $logger->debug( $assert . 'LF' )
                        }
                        default {
                            $logger->debug(
                                "Unknown input record separator: [$/]")
                        }

                    }

                }

                unless (( defined( $data{$fh_bytes} ) )
                    and ( $data{$fh_bytes} > 0 ) )
                {

                    $data{$fh_bytes} =
                      sysread( $fh, $data{$fh_name}, $self->get_buffer_size() );

                }
                else {

                    $logger->info(
                        'Caught part of a record, repeating sysread with offset'
                    ) if ( $logger->is_info() );

                    my $offset =
                      length( Encode::encode_utf8( $data{$fh_name} ) );

                    $logger->debug("Offset is $offset")
                      if ( $logger->is_debug() );

                    $data{$fh_bytes} =
                      sysread( $fh, $data{$fh_name},
                        $self->get_buffer_size(), $offset );

                }

                unless ( defined( $data{$fh_bytes} ) ) {

                    $logger->fatal( 'sysread returned an error: ' . $! );

                    $self->_check_child($logger);

                    $logger->logdie( 'sysreading from '
                          . $fh_name
                          . ' returned an unrecoverable error' )
                      ;    # unless ( $!{ECONNRESET} );

                }
                else {

                    if ( $data{$fh_bytes} == 0 ) {

                        $select->remove($fh);
                        next;

                    }

                    if (    ( $data{$fh_bytes} == $self->get_buffer_size() )
                        and ( $data{$fh_name} !~ /\015\012$/ ) )
                    {

                        $logger->debug(
                            'Buffer DOES NOT have CRLF at the end of it');

                        next READ;

                    }

                    $logger->debug("Read $data{$fh_bytes} bytes from $fh_name")
                      if ( $logger->is_debug() );

                    if ( $fh == $self->get_read() ) {

# :WORKAROUND:14/08/2013 18:40:46:: necessary to empty the stdout for possible (useless) information hanging in the buffer, but
# this information must be discarded since is from the previous processed command submitted
# :TODO      :14/08/2013 18:41:43:: check why such information is not being recovered in the previous execution
                        $self->_process_stdout( \$data{$fh_name},
                            \@input_buffer, $logger, $condition )
                          unless ($ignore_output);

                        $data{$fh_name}  = undef;
                        $data{$fh_bytes} = 0;

                    }
                    elsif ( $fh == $self->get_error() ) {

                        $self->_process_stderr( \$data{$fh_name}, $logger );

                        $data{$fh_name}  = undef;
                        $data{$fh_bytes} = 0;

                    }
                    else {
                        $logger->logdie(
                            'Somehow got a filehandle I dont know about!');
                    }
                }

            }    # end of foreach block

        }    # end of while block

        # below is the place for a Action object
        if ( scalar(@input_buffer) >= 1 ) {

# :TRICKY:5/1/2012 17:43:58:: copy params to avoid operations that erases the parameters due passing an array reference and messing with it
            my @params;

            map { push( @params, $_ ) }
              @{ $self->get_params_stack()->[ $condition->get_cmd_counter() ] };

            my $class =
              $self->get_action_stack()->[ $condition->get_cmd_counter() ];

            if ( $logger->is_debug() ) {

                $logger->debug(
"Creating Siebel::Srvrmgr::Daemon::Action subclass $class instance"
                );

            }

            my $action = Siebel::Srvrmgr::Daemon::ActionFactory->create(
                $class,
                {
                    parser => $parser,
                    params => \@params

                }
            );

 # :TODO      :16/08/2013 19:03:30:: remove this log statement to Siebel::Srvrmgr::Daemon::Action
            if ( $logger->is_debug() ) {

                $logger->debug('Lines from buffer sent for parsing');

                foreach my $line (@input_buffer) {

                    $logger->debug($line);

                }

                $logger->debug('End of lines from buffer sent for parsing');

            }

# :WORKAROUND:16/08/2013 18:54:51:: exceptions from validating output are not being seem
# :TODO      :16/08/2013 18:55:18:: start using TryCatch to use exceptions for known problems
            eval {

                $condition->set_output_used( $action->do( \@input_buffer ) );

            };

            $logger->fatal($@) if ($@);

            $logger->debug( 'Is output used? ' . $condition->is_output_used() )
              if ( $logger->is_debug() );
            @input_buffer = ();

        }
        else {

            $logger->debug('buffer is empty');

        }

        $logger->debug('Finished processing buffer')
          if ( $logger->is_debug() );

# :TODO:27/2/2012 17:43:42:: must deal with command stack when the loop is infinite (invoke reset method)

        # begin of session, sending command to the prompt
        unless ( $condition->is_cmd_sent() or $condition->is_last_cmd() ) {

            $logger->debug('Preparing to execute command')
              if ( $logger->is_debug() );

            $condition->add_cmd_counter()
              if ( $condition->can_increment() );

            my $cmd = $self->get_cmd_stack()->[ $condition->get_cmd_counter() ];

            unless ( defined($cmd) ) {

                $logger->logwarn('Invalid command received for execution');
                $logger->logdie( Dumper( $self->get_cmd_stack() ) );

            }
            else {

                $logger->debug("Submitting $cmd")
                  if ( $logger->is_debug() );

            }

            $self->_submit_cmd( $cmd, $logger );

            $ignore_output = 0;

# srvrmgr.exe of Siebel 7.5.3.17 does not echo command printed to the input file handle
# this is necessary to give a hint to the parser about the command submitted

            if ( defined( $self->get_prompt() ) ) {

                push( @input_buffer, $self->get_prompt() . $cmd );
                $self->_set_last_cmd( $self->get_prompt() . $cmd );

            }
            else {

                $logger->logdie(
                    'prompt was not defined from read output, cannot continue');

            }

            $condition->set_output_used(0);
            $condition->set_cmd_sent(1);

            sleep( $self->get_wait_time() );

        }
        else {

            if ( $logger->is_debug() ) {

                $logger->debug('Not yet read to execute a command');
                $logger->debug(
                    'Condition max_cmd_idx = ' . $condition->max_cmd_idx() );
                $logger->debug(
                    'Condition is_cmd_sent = ' . $condition->is_cmd_sent() );

            }

        }

# :TODO      :31/07/2013 16:43:15:: Condition class should have their own logger
# it is not possible to call check() twice because of the invocation of reduce_total_cmd() by check()
# if the Daemon has only one command, it will enter in a loop invoking srvrmgr everytime without doing
# nothing with it's output
        $temp = $condition->check();

        $logger->info( 'Continue executing? ' . $temp )
          if ( $logger->is_info() );

    } while ($temp);

    $self->_set_child_runs( $self->get_child_runs() + 1 );
    $logger->debug( 'child_runs = ' . $self->get_child_runs() )
      if ( $logger->is_debug() );
    $logger->info('Exiting run sub');

    return 1;

}

sub _create_child {

    my $self = shift;

    if ( $self->get_retries() >= $self->get_max_retries() ) {

        my $logger = __PACKAGE__->_gimme_logger();
        weaken($logger);
        $logger->fatal( 'Maximum retries to spawn srvrmgr reached: '
              . $self->get_max_retries() );
        $logger->warn(
'Application will exit with an error return code. Please review log for errors'
        );
        exit(1);

    }

    die 'Cannot find program ' . $self->get_bin() . " to execute\n"
      unless ( -e $self->get_bin() );

    my @params;

    if ( defined( $self->get_server() ) ) {

        @params = (
            $self->get_bin(),      '/e', $self->get_enterprise(), '/g',
            $self->get_gateway(),  '/u', $self->get_user(),       '/p',
            $self->get_password(), '/s', $self->get_server(),     '/l',
            $self->get_lang_id()
        );

    }
    else {

        @params = (
            $self->get_bin(),        '/e',
            $self->get_enterprise(), '/g',
            $self->get_gateway(),    '/u',
            $self->get_user(),       '/p',
            $self->get_password(),   '/l',
            $self->get_lang_id()

        );

    }

# :WORKAROUND:06/08/2013 21:05:32:: if a perlscript will be executed (like for automated testing of this distribution)
# then the perl interpreter must be part of the command path to avoid open3 calling cmd.exe (in Microsoft Windows)
    unshift( @params, $Config{perlpath} ) if ( $self->use_perl() );

    my ( $pid, $write_h, $read_h, $error_h ) = safe_open3( \@params );
    $self->_set_pid($pid);
    $self->_set_write($write_h);
    $self->_set_read($read_h);
    $self->_set_error($error_h);

    my $logger = __PACKAGE__->_gimme_logger();
    weaken($logger);

    if ( $logger->is_debug() ) {

        $logger->debug( 'Forked srvrmgr with the following parameters: '
              . join( ' ', @params ) );
        $logger->debug( 'child PID is ' . $pid );
        $logger->debug( 'IPC buffer size is ' . $self->get_buffer_size() );

    }

    $logger->info('Started srvrmgr');

    unless ( $self->_check_child($logger) ) {

        return 0;

    }
    else {

        $self->_set_child_runs(0);
        return $logger;

    }

}

sub _process_stderr {

    exit if ($SIG_INT);
    my $self     = shift;
    my $data_ref = shift;
    my $logger   = shift;
    weaken($logger);

    if ( defined($$data_ref) ) {

        foreach my $line ( split( "\n", $$data_ref ) ) {

            exit if ($SIG_INT);

# :WORKAROUND:09/08/2013 19:12:55:: in MS Windows OS, srvrmgr returns CR characters "alone"
# like "CRCRLFCRCRLF" for two empty lines. And yes, that sucks big time
            $line =~ s/\r$//;
            $self->_check_error( $line, $logger );

        }

    }
    else {

        $logger->warn('Received empty buffer to read');

    }

}

sub _process_stdout {

# :TODO      :07/08/2013 15:12:17:: should this be controlled in instances? or should it be global to the class?
    exit if ( $SIG_INT or $SIG_PIPE );

    my $self       = shift;
    my $data_ref   = shift;
    my $buffer_ref = shift;
    my $logger     = shift;
    my $condition  = shift;

    weaken($logger);

# :TODO      :09/08/2013 19:35:30:: review and remove assigning the compiled regexes to scalar (probably unecessary)
    my $prompt_regex    = SRVRMGR_PROMPT;
    my $load_pref_regex = LOAD_PREF_RESP;
    my $rows_returned   = ROWS_RETURNED;
    my $error           = SIEBEL_ERROR;

    $logger->debug("Raw content is [$$data_ref]") if $logger->is_debug();

    foreach my $line ( split( "\n", $$data_ref ) ) {

        exit if ( $SIG_INT or $SIG_PIPE );

# :WORKAROUND:09/08/2013 19:12:55:: in MS Windows OS, srvrmgr returns CR characters "alone"
# like "CRCRLFCRCRLF" for two empty lines. And yes, that sucks big time
        $line =~ s/\r$//;

        if ( $logger->is_debug() ) {

            if ( defined($line) ) {

                $logger->debug("Recovered line [$line]");

            }
            else {

                $logger->debug("Recovered line with undefined content");

            }

        }

        given ($line) {

            when (/$error/) {

                $self->_check_error( $line, $logger );

            }

# :TRICKY:29/06/2011 21:23:11:: bufferization in srvrmgr.exe ruins the day: the prompt will never come out unless a little push is given
            when (/$rows_returned/) {

                # parsers will consider the lines below
                push( @{$buffer_ref}, $line );

# :TODO      :08/08/2013 15:25:46:: check if sending a new line without anything else is still necessary after select() implementation
#syswrite $self->get_write(), "\n";

            }

            # prompt was returned, end of output
            # first execution should bring only informations about Siebel
            when (/$prompt_regex/) {

                unless ( defined( $self->get_prompt() ) ) {

                    $self->_set_prompt($line);

                    $logger->info("defined prompt with [$line]")
                      if ( $logger->is_info() );

# if prompt was undefined, that means that this is might be rest of output of previous command
# and thus can be safely ignored
                    if ( @{$buffer_ref} ) {

                        if ( $buffer_ref->[0] eq '' ) {

                            $logger->debug("Ignoring output [$line]");

                            $condition->set_cmd_sent(0);
                            @{$buffer_ref} = ();

                        }

                    }

                }
                elsif ( scalar( @{$buffer_ref} ) < 1 ) {  # no command submitted

                    $condition->set_cmd_sent(0);

                }
                else {

                    unless (( scalar( @{$buffer_ref} ) >= 1 )
                        and ( $buffer_ref->[0] eq $self->get_last_cmd() )
                        and $condition->is_cmd_sent() )
                    {

                        $condition->set_cmd_sent(0);

                    }

# this is specific for load preferences response since it may contain the prompt string (Siebel 7.5.3.17)
                    if ( $line =~ /$load_pref_regex/ ) {

                        push( @{$buffer_ref}, $line );

                        #syswrite $self->get_write(), "\n";

                    }

                }

            }

# no prompt detection, keep reading output from srvrmgr.exe
# :WARNING   :03/06/2013 18:22:40:: might cause a deadlock if the srvrmgr does not have anything else to read
            default { push( @{$buffer_ref}, $line ); }

        }

    }

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

sub _check_child {

    my $self   = shift;
    my $logger = shift;
    weaken($logger);

    if ( $self->has_pid() ) {

        # try to read immediatly from stderr if possible
        if ( openhandle( $self->get_error() ) ) {

            my $error;

            my $select = IO::Select->new();
            $select->add( $self->get_error() );

            while ( my $fh = $select->can_read( $self->get_read_timeout() ) ) {

                my $buffer;
                my $read = sysread( $fh, $buffer, $self->get_buffer_size() );

                if ( defined($read) ) {

                    if ( $read > 0 ) {

                        $error .= $buffer;
                        next;

                    }
                    else {

                        $logger->debug(
                            'Reached EOF while trying to get error messages')
                          if ( $logger->is_debug() );

                    }

                }
                else {

                    $logger->warn(
                        'Could not sysread the STDERR from srvrmgr process: '
                          . $! );
                    last;

                }

            }    # end of while block

            $self->_process_stderr( \$error, $logger ) if ( defined($error) );

        }
        else {

            $logger->fatal('Error pipe from child is closed');

        }

        $logger->fatal('Read pipe from child is closed')
          unless ( openhandle( $self->get_read() ) );
        $logger->fatal('Write pipe from child is closed')
          unless ( openhandle( $self->get_write() ) );

# :WORKAROUND:19/4/2012 19:38:04:: somehow the child process of srvrmgr has to be waited for one second and receive one kill 0 signal before
# it dies when something goes wrong
        sleep 1;
        kill 0, $self->get_pid();

        unless ( kill 0, $self->get_pid() ) {

            $logger->fatal( $self->get_bin()
                  . " process returned a fatal error: ${^CHILD_ERROR_NATIVE}" );

            $logger->fatal( $? . ' child exit status = ' . ( $? >> 8 ) );

            $self->close_child($logger);

            return 0;

        }
        else {

            return 1;

        }

    }    # end of if has_pid
    else {

        return 0;

    }

}

=pod

=head2 DEMOLISH

This method is invoked before the object instance is destroyed. It will try to close the connection with the Siebel Enterprise (if opened)
by submitting the command C<exit>.

It will then try to read the string "Disconnecting from server" from the generated output after the command submission and closing the opened
filehandles right after. Then it will send a C<kill 0> signal to the process to check if it is still running.

Finally, it will wait for 5 seconds before calling C<waitpid> function to rip the child process.

=cut

sub DEMOLISH {

    my $self = shift;

    my $logger = __PACKAGE__->_gimme_logger();
    weaken($logger);

    $logger->info('Terminating daemon');

    if ( $self->has_pid() and ( $self->get_pid() =~ /\d+/ ) ) {

        $self->close_child($logger);

    }
    else {

        if ( $logger->is_info() ) {

            $logger->info("Program termination was forced") if ($SIG_ALARM);
            $logger->info(
'srvrmgr program was not yet executed, no child process to terminate'
            );
            $logger->info('daemon says bye-bye');

        }

    }

}

sub _term_INT {

    $SIG_INT = 1;

}

sub _term_PIPE {

    $SIG_PIPE = 1;
    warn "got SIGPIPE\n";

}

sub _term_ALARM {

    $SIG_ALARM = 1;

}

sub _gimme_logger {

    my $cfg = Siebel::Srvrmgr->logging_cfg();

    die "Could not start logging facilities"
      unless ( Log::Log4perl->init_once( \$cfg ) );

    return Log::Log4perl->get_logger('Siebel::Srvrmgr::Daemon');

}

sub _submit_cmd {

    my $self       = shift;
    my $cmd        = shift;
    my $logger     = shift;
    my $has_logger = 0;

    if ( ( defined($logger) ) and ( ref($logger) ) ) {

        weaken($logger);
        $has_logger = 1;

    }

    # for better security
    unless ( ( $cmd =~ /^load/ )
        or ( $cmd =~ /^list/ )
        or ( $cmd =~ /^exit/ ) )
    {

        if ($has_logger) {

            $logger->logdie(
                "Insecure command from command stack [$cmd]. Execution aborted"
            );

        }
        else {

            die( "Insecure command from command stack [$cmd]. Execution aborted"
            );

        }

    }

    my $bytes = syswrite $self->get_write(), "$cmd\n";

    if ( defined($bytes) ) {

        if ( $has_logger && $logger->is_debug() ) {

            $logger->debug("Submitted $cmd, wrote $bytes bytes");

        }

    }
    else {

        if ($has_logger) {

            $logger->logdie( 'A failure occurred when trying to submit '
                  . $cmd . ': '
                  . $! );

        }
        else {

            die(    'A failure occurred when trying to submit '
                  . $cmd . ': '
                  . $! );

        }

    }

    return 1;

}

=pod

=head2 close_child

Finishes the child process associated with the execution of srvrmgr program, if the child's PID is available. Besides, this automatically calls C<clear_pid>.

First this methods tries to submit the C<exit> command to srvrmgr, hoping to terminate the connection with the Siebel Enterprise. After that, the
handles associated with the child will be closed. If after that the PID is still running, the method will call C<waitpid> in non-blocking mode.

For MS Windows OS, this might not be sufficient: the PID will be checked again after C<waitpid>, and if it is still running, this method will try to use
C<kill 9> to eliminate the process.

If the child process is terminated succesfully, this method returns true. If there is no PID associated with the Daemon instance, this method will return false.

Accepts as an optional parameter, an instance of a L<Log::Log4perl> for logging messages.

=cut

sub close_child {

    my $self   = shift;
    my $logger = shift;

    my $has_logger = 0;

# :WORKAROUND:16/08/2013 12:23:40:: even if the child process is not killed, a new process need to be created
# :TODO      :16/08/2013 12:24:06:: make this behaviour optional (like, try a new child or simply die if not possible)
    $self->clear_pid();

    if ( ( defined($logger) ) and ( ref($logger) ) ) {

        weaken($logger);
        $has_logger = 1;

    }

    if ( $self->has_pid() ) {

        if ( $has_logger && $logger->is_warn() ) {

            $logger->warn('Got SIGPIPE') if ($SIG_PIPE);
            $logger->warn('Got SIGINT')  if ($SIG_INT);
            $logger->warn('Got SIGALRM') if ($SIG_ALARM);
            $logger->warn( 'Trying to close child PID ' . $self->get_pid() );

        }

        my @handles = ( $self->get_error(), $self->get_read() );
        my @handles_names = (qw(error_fh read_fh));

        for ( my $i = 0 ; $i <= 1 ; $i++ ) {

            if ( openhandle( $handles[$i] ) ) {

                if ($has_logger) {

                    $logger->debug(
                        "Trying to close child $handles_names[$i] handle")
                      if ( $logger->is_debug() );

                    close( $self->get_error() )
                      or $logger->fatal(
                        "Could not close $handles_names[$i] handle: $!");

                }
                else {

                    close( $handles[$i] )
                      or warn("Could not close $handles_names[$i] handle: $!");

                }

            }
            else {

                if ($has_logger) {

                    $logger->warn("$handles_names[$i] is already closed");

                }

            }

        }

        @handles = undef;

        if (    ( openhandle( $self->get_write() ) )
            and ( not($SIG_PIPE) )
            and ( not($SIG_ALARM) ) )
        {

            $self->_submit_cmd( 'exit', $logger );

            if ( $has_logger && $logger->is_debug() ) {

                $logger->debug(
'Submitted exit command to srvrmgr. Trying to close child write handle'
                );
                close( $self->get_write() )
                  or $logger->logdie("Could not close write handle: $!");

            }
            else {

                close( $self->get_write() )
                  or die("Could not close write handle: $!");

            }

        }
        else {

            $logger->warn('write_fh is already closed') if ($has_logger);

        }

        sleep( $self->get_child_timeout() );

        if ( kill 0, $self->get_pid() ) {

            if ( $has_logger && $logger->is_debug() ) {

                $logger->debug('srvrmgr is still running, trying to kill it');

            }

            my $ret = waitpid( $self->get_pid(), WNOHANG );

            given ($ret) {

                when ( $self->get_pid() ) {

# :WORKAROUND:14/08/2013 17:44:00:: for Windows, not using shutdown when creating the socketpair causes the application to not
# exit with waitpid. using waitpid without non-blocking mode just blocks the application to finish
                    if ( $Config{osname} eq 'MSWin32' ) {

                        if ( kill 0, $self->get_pid() ) {

                            $logger->warn(
'child is still running even after waitpid: last attempt with "kill 9"'
                            ) if ($has_logger);

                            kill 9, $self->get_pid();

                        }

                    }

                    $logger->info('Child process finished successfully')
                      if ( $has_logger && $logger->is_info() );

                }

                when (-1) {

                    $logger->info(
                        'No such PID ' . $self->get_pid() . ' to kill' )
                      if ( $has_logger && $logger->is_info() );

                }

                default {

                    if ( $has_logger && $logger->is_warn() ) {

                        $logger->warn('Could not kill the child process');
                        $logger->warn( 'Child status = ' . $? );
                        $logger->warn(
                            'Child error = ' . ${^CHILD_ERROR_NATIVE} );

                    }

                }

            }

        }
        else {

            $logger->warn('child process is already gone')
              if ( $has_logger && $logger->is_warn() );

        }

        return 1;

    }
    else {

        $logger->info('Has no child PID available to close')
          if ( $has_logger && $logger->is_info() );
        return 0;

    }

}

=pod

=head1 CAVEATS

This class is still considered experimental and should be used with care.

The C<srvrmgr> program uses buffering, which makes difficult to read the generated output as expected.

=head1 SEE ALSO

=over 8

=item *

L<IPC::Open2>

=item *

L<Moose>

=item *

L<Siebel::Srvrmgr::Daemon::Condition>

=item *

L<Siebel::Srvrmgr::Daemon::Command>

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

=item *

L<https://github.com/lucastheisen/ipc-open3-callback>

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

