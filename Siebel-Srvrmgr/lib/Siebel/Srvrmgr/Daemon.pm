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
use Scalar::Util qw(weaken);
use Config;
use Siebel::Srvrmgr::IPC;
use IO::Select;

$SIG{INT}  = \&_term_INT;
$SIG{PIPE} = \&_term_PIPE;
$SIG{ALRM} = \&_term_ALARM;

our $SIG_INT   = 0;
our $SIG_PIPE  = 0;
our $SIG_ALARM = 0;

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

has harness => (
    isa    => 'IPC::Run',
    is     => 'ro',
    writer => '_set_harness',
    reader => 'get_harness'
);

=pod

=head2 pid

An integer presenting the process id (PID) of the process created by the OS when the C<srvrmgr> program is executed.

This is a read-only attribute.

=cut

has pid =>
  ( isa => 'Int', is => 'ro', writer => '_set_pid', reader => 'get_pid' );

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

If true, if will prepend the complete path of the Perl interpreter to the parameters before calling the C<srvrmgr> program (of course, the srvrmgr must
be itself a Perl script).

It defaults to false.

=cut

has use_perl =>
  ( isa => 'Bool', is => 'ro', reader => 'use_perl', default => 0 );

=pod

=head1 METHODS

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

    my ( $read_h, $write_h, $error_h );

# :WORKAROUND:31/07/2013 14:42:33:: must initialize the Log::Log4perl after forking the srvrmgr to avoid sharing filehandles
    unless ( $self->get_pid() ) {

        $logger = $self->_create_child();

    }
    else {

        $logger = __PACKAGE__->_gimme_logger();
        weaken($logger);
        $logger->info( 'Reusing PID ', $self->get_pid() )
          if ( $logger->is_debug() );

    }

    $logger->info('Starting run method');

# :WARNING:28/06/2011 19:47:26:: reading the output is hanging without a dummy input
    syswrite $self->get_write(), "\n";

    my $prompt;
    my @input_buffer;

# :TODO      :06/08/2013 19:13:47:: create condition as a hidden attribute of this class
    my $condition = Siebel::Srvrmgr::Daemon::Condition->new(
        {
            is_infinite    => $self->is_infinite(),
            total_commands => scalar( @{ $self->get_commands() } ),
            cmd_sent       => 0
        }
    );

    my $read_timeout = 10;
    my $parser       = Siebel::Srvrmgr::ListParser->new();

    my $select = IO::Select->new();
    $select->add( $self->get_read(), $self->get_error() );

    do {

        exit if ($SIG_INT);

        $logger->debug(
            "Setting $read_timeout seconds for read srvrmgr output time out")
          if ( $logger->is_debug() );
        alarm($read_timeout);

        while ( my @ready = $select->can_read($read_timeout) ) {

            foreach my $fh (@ready) {

                my $data;
                my $bytesRead = sysread( $fh, $data, 1024 );

                if ( !( defined($bytesRead) ) and ( !$!{ECONNRESET} ) ) {
                    $logger->logdie(
                        'sysread failed reading from srvrmgr:' . $! );
                }
                elsif ( !defined($bytesRead) || $bytesRead == 0 ) {
                    $select->remove($fh);
                    next;
                }
                else {

                    if ( $fh == $self->get_read() ) {
                        $prompt =
                          $self->_process_stdout( \$data, \@input_buffer,
                            $logger, $condition );
                    }
                    elsif ( $fh == $self->get_error() ) {

                        $self->_process_stderr( \$data );
                    }
                    else {
                        $logger->logdie(
                            'Somehow got a filehandle i dont know about!');
                    }
                }
            }

        }

        my $time_remaining = 0;
        $time_remaining = alarm(0);

        $logger->debug(
"Reseting the time out for reading srvrmgr output (time remaing $time_remaining seconds)"
        ) if ( $logger->is_debug() );

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

            if ( $logger->is_debug() ) {

                $logger->debug('First three lines of buffer sent for parsing');

                for ( my $i = 0 ; $i <= 2 ; $i++ ) {

                    if ( defined( $input_buffer[$i] ) ) {

                        $logger->debug( $input_buffer[$i] );

                    }
                    else {

                        $logger->debug('undefined content');

                    }

                }

            }

            $condition->set_output_used( $action->do( \@input_buffer ) );

            $logger->debug( 'Is output used? ' . $condition->is_output_used() )
              if ( $logger->is_debug() );
            @input_buffer = ();

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

            # for better security
            $logger->logdie(
                "Insecure command from command stack [$cmd]. Execution aborted")
              unless ( ( $cmd =~ /^load/ ) or ( $cmd =~ /^list/ ) );

            syswrite $self->get_write(), "$cmd\n";

# srvrmgr.exe of Siebel 7.5.3.17 does not echo command printed to the input file handle
# this is necessary to give a hint to the parser about the command submitted

            if ( defined($prompt) ) {

                push( @input_buffer, $prompt . $cmd );
                $self->_set_last_cmd( $prompt . $cmd );

            }
            else {

                $logger->info('prompt was not defined from read output');
                push( @input_buffer, $cmd );
                $self->_set_last_cmd($cmd);

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

    $logger->info('Exiting run sub');

    return 1;

}

sub _create_child {

    my $self   = shift;
    my $logger = shift;

# :WORKAROUND:06/08/2013 21:05:32:: if a perlscript will be executed (like for automated testing of this distribution)
# then the perl interpreter must be part of the command path to avoid open3 calling cmd.exe (in Microsoft Windows)
    die 'Cannot find program ' . $self->get_bin() . " to execute\n"
      unless ( -e $self->get_bin() );

    my @params;

    if ( defined( $self->get_server() ) ) {

        @params = (
            $self->get_bin(),      '/e', $self->get_enterprise(), '/g',
            $self->get_gateway(),  '/u', $self->get_user(),       '/p',
            $self->get_password(), '/s', $self->get_server()
        );

    }
    else {

        @params = (
            $self->get_bin(),        '/e',
            $self->get_enterprise(), '/g',
            $self->get_gateway(),    '/u',
            $self->get_user(),       '/p',
            $self->get_password()

        );

    }

    unshift( @params, $Config{perlpath} ) if ( $self->use_perl() );

    my ( $pid, $write_h, $read_h, $error_h ) = safe_open3( \@params );
    $logger = __PACKAGE__->_gimme_logger();
    weaken($logger);

    if ( $logger->is_debug() ) {

        $logger->debug( 'forked srvrmgr with the following parameters: '
              . join( ' ', @params ) );
        $logger->debug( 'child PID is ' . $pid );

    }

    $logger->info('Started srvrmgr');

# :WORKAROUND:19/4/2012 19:38:04:: somehow the child process of srvrmgr has to be waited for one second and receive one kill 0 signal before
# it dies when something goes wrong
    sleep 1;
    kill 0, $pid;

    unless ( kill 0, $pid ) {

        $logger->logdie( $self->get_bin()
              . " process returned a fatal error: ${^CHILD_ERROR_NATIVE}" );

    }

    $self->_set_pid($pid);
    $self->_set_write($write_h);
    $self->_set_read($read_h);
    $self->_set_error($error_h);

    return $logger;

}

sub _process_stderr {

    exit if ($SIG_INT);
    my $self = shift;
    my $line = shift;

    $line =~ s/\r\n//;
    $line =~ s/\n//;

    $self->_check_error($line);

}

sub _process_stdout {

    exit if ($SIG_INT);

    my $self       = shift;
    my $data_ref   = shift;
    my $buffer_ref = shift;
    my $logger     = shift;
    my $condition  = shift;

    weaken($logger);
    my $prompt_regex    = SRVRMGR_PROMPT;
    my $load_pref_regex = LOAD_PREF_RESP;
    my $rows_returned   = ROWS_RETURNED;
    my $error           = SIEBEL_ERROR;
    my $prompt;

    foreach my $line ( split( "\n", $$data_ref ) ) {

        # :WORKAROUND:06/08/2013 20:22:59:: should work for Windows and UNIX
        $line =~ s/\r\n$//;
        $line =~ s/\n$//;

        if ( $logger->is_debug() ) {

            if ( defined($line) ) {

                $logger->debug("Read [$line] from srvrmgr");

            }
            else {

                $logger->debug("Read [undefined content] from srvrmgr");

            }

        }

        given ($line) {

            when (/$error/) {

                $self->_check_error($line);

            }

# :TRICKY:29/06/2011 21:23:11:: bufferization in srvrmgr.exe ruins the day: the prompt will never come out unless a little push is given
            when (/$rows_returned/) {

                # parsers will consider the lines below
                push( @{$buffer_ref}, $line );
                push( @{$buffer_ref}, '' );

                syswrite $self->get_write(), "\n";

            }

            # prompt was returned, end of output
            # first execution should bring only informations about Siebel
            when (/$prompt_regex/) {

                unless ( defined($prompt) ) {

                    $prompt = $line;

                    if ( $logger->is_debug() ) {

                        $logger->debug("defined prompt with [$line]");

                    }

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
                        syswrite $self->get_write(), "\n";

                    }

                }

            }

# no prompt detection, keep reading output from srvrmgr.exe
# :WARNING   :03/06/2013 18:22:40:: might cause a deadlock if the srvrmgr does not have anything else to read
            default { push( @{$buffer_ref}, $line ); }

        }

    }

    return $prompt;

}

sub _check_error {

    my $self   = shift;
    my $line   = shift;
    my $logger = shift;

    weaken($logger);

    # caught an error, until now all they are fatal

    $logger->fatal($line);

    given ($line) {

        when (/^SBL-ADM-60070.*/) {

            # instead of dying, try to read the next line
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

    # only the parent process has the pid defined
    if (    ( defined( $self->get_pid() ) )
        and ( $self->get_pid() =~ /\d+/ ) )
    {

        if (    ( defined( $self->get_write() ) )
            and ( defined( $self->get_read() ) )
            and ( not($SIG_PIPE) )
            and ( not($SIG_ALARM) ) )
        {

            syswrite $self->get_write(), "exit\n";
            syswrite $self->get_write(), "\n";

            # after the exit command the srvrmgr program already exited
            unless ($SIG_PIPE) {

                if ( $logger->is_debug() ) {

                    $logger->debug(
                        'DEMOLISH invoked, getting last output from srvrmgr');

                    my $rdr = $self->get_read()
                      ;  # diamond operator does not like method calls inside it

                    while (<$rdr>) {

                        if (/^Disconnecting from server\./) {

                            $logger->debug( chomp($_) );
                            last;

                        }
                        else {

                            $logger->debug( chomp($_) );

                        }

                    }

                }

            }

        }

        close( $self->get_read() )  if ( defined( $self->get_read() ) );
        close( $self->get_write() ) if ( defined( $self->get_write() ) );
        close( $self->get_error() ) if ( defined( $self->get_error() ) );

        if ( kill 0, $self->get_pid() ) {

            sleep( $self->get_child_timeout() );

            if ( $logger->is_debug() ) {

                $logger->debug('srvrmgr is still running, trying to kill it');

            }

            my $ret = waitpid( $self->get_pid(), WNOHANG );

            if ( $logger->is_debug() ) {

                if ( $? == 0 ) {

                    $logger->debug('Child process finished successfully');

                }
                else {

                    $logger->debug(
'Something went bad with child process: look for orphan process'
                    );

                }

                $logger->debug(
"Ripped PID = $ret, status = $?, child error native = ${^CHILD_ERROR_NATIVE}"
                );
            }

        }

        $logger->info("Program termination was forced")
          if ($SIG_ALARM);

    }
    else {

        $logger->info(
'srvrmgr program was not yet executed, no child process to terminate'
        );

    }

    $logger->info('daemon says bye-bye');

}

sub _term_INT {

    $SIG_INT = 1;

}

sub _term_PIPE {

    $SIG_PIPE = 1;

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

=pod

=head1 CAVEATS

This class is still considered experimental and should be used with care.

The C<srvrmgr> program uses buffering, which makes difficult to read the generated output as expected.

The C<open2> function in Win32 system is still returnin a PID even when an error occurs when executing the C<srvrmgr> program.

L<IPC::Cmd> looks like to a portable solution for those problems but that was not tested till now.

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