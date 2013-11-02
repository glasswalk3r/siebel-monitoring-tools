package Siebel::Srvrmgr::Daemon::Heavy;

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon::Heavy - "heavier' implementation of Siebel::Srvrmgr::Daemon

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

This class is the "heavier" version of L<Siebel::Srvmrgr::Daemon>. By heavier, understand more complex code to be able to deal with a heavier usage
of srvrmgr.

This class is indicated to be used in cenarios where several commands need to be executed in a short time interval: it will connect to srvrmgr by using 
IPC for communication between the processes and once connected, the srvrmgr session will be reused as many times as desired instead of following the
sequence of connect -> run commands -> disconnect.

The sessions are not "interactive" from the user point of view but the usage of this class enable the adoption of some logic to change how the commands will 
be executed or even generate commands on the fly.

This module is based on L<IPC::Open3::Callback> from Lucas Theisen (see SEE ALSO section) implemented in L<Siebel::Srvrmgr::Daemon::IPC>.

Since it uses Perl IPC, this class may suffer from good support in OS plataforms that are not UNIX-like. Be sure to check out tests results of the distribution
before trying to use it.

=cut

use Moose;
use namespace::autoclean;
use Siebel::Srvrmgr::Daemon::Condition;
use Siebel::Srvrmgr::Daemon::ActionFactory;
use Siebel::Srvrmgr::ListParser;
use Siebel::Srvrmgr::Regexes
  qw(SRVRMGR_PROMPT LOAD_PREF_RESP SIEBEL_ERROR ROWS_RETURNED);
use Siebel::Srvrmgr::Daemon::Command;
use POSIX;
use Data::Dumper;
use Scalar::Util qw(weaken openhandle);
use Config;
use Siebel::Srvrmgr::IPC;
use IO::Select;
use Encode;
use Carp qw(longmess);
use Socket qw(:crlf);
use Siebel::Srvrmgr;

extends 'Siebel::Srvrmgr::Daemon';

our $SIG_INT   = 0;
our $SIG_PIPE  = 0;
our $SIG_ALARM = 0;

# :TODO      :16/08/2013 19:02:24:: add statistics for daemon, like number of runs and average of used buffer for each command

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

The timeout for trying to read from child process handlers in seconds. It defaults to 3 seconds.

Changing this value may help improving performance, but should be used with care.

=cut

has read_timeout => (
    isa     => 'Int',
    is      => 'rw',
    writer  => 'set_read_timeout',
    reader  => 'get_read_timeout',
    default => 3
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

sub _add_retry {

    my ( $self, $new, $old ) = @_;

    # if $old is undefined, this is the first call to run method
    unless ( defined($old) ) {

        return 0;

    }
    else {

        unless ( $new == $old ) {

            $self->_set_retries( $self->get_retries() + 1 );
            return 1;

        }
        else {

            return 0;

        }

    }

}

=pod

=head2 BUILD

This methods calls C<clear_pid> just to have a sane setting on C<child_pid> attribute.

=cut

sub BUILD {

    my $self = shift;
    $self->clear_pid();

}

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

=head2 ipc_buffer_size

A integer describing the size of the buffer used to read output from srvrmgr program by using IPC.

It defaults to 5120 bytes, but it can be adjusted to improve performance (lowering CPU usage by increasing memory utilization).

Increase of this attribute should be considered experimental.

=cut

has ipc_buffer_size => (
    isa     => 'Int',
    is      => 'rw',
    reader  => 'get_buffer_size',
    writer  => 'set_buffer_size',
    default => 5120
);

=head2 srvrmgr_prompt

An string representing the prompt recovered from srvrmgr program. The value of this attribute is set automatically during srvrmgr execution.

=cut

has srvrmgr_prompt =>
  ( isa => 'Str', is => 'ro', reader => 'get_prompt', writer => '_set_prompt' );

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

=head2 get_buffer_size

Returns the value of the attribute C<ipc_buffer_size>.

=head2 set_buffer_size

Sets the attribute C<ipc_buffer_size>. Expects an integer as parameter, multiple of 1024.

=head2 get_write

Returns the file handle of STDIN from the process executing the srvrmgr program based on the value of the attribute C<write_fh>.

=head2 get_read

Returns the file handle of STDOUT from the process executing the srvrmgr program based on the value of the attribute C<read_fh>.

=head2 get_error

Returns the file handle of STDERR from the process executing the srvrmgr program based on the value of the attribute C<error_fh>.

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

=cut

override '_setup_commands' => sub {

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

};

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

        $logger = Siebel::Srvrmgr->gimme_logger( ref($self) );
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

    my $parser   = Siebel::Srvrmgr::ListParser->new();
    my $select   = IO::Select->new();
    my $data_ref = $self->_create_handle_buffer( $select, $logger );

    my $prompt_regex = qr/srvrmgr(\:\w+)?>\s(.*)?$/;
    my $eol_regex    = qr/$CRLF$/;

    $logger->debug( 'sysread buffer size is ' . $self->get_buffer_size() )
      if ( $logger->is_debug() );

    do {

        exit if ($SIG_INT);

# :TODO:18-10-2013:arfreitas: move all code inside the while block to a different method to help and clean up lexicals
        while ( my @ready = $select->can_read( $self->get_read_timeout() ) ) {

            foreach my $fh (@ready) {

                my $fh_name  = fileno($fh);
                my $fh_bytes = $fh_name . '_bytes';

                $logger->debug( 'Reading filehandle ' . fileno($fh) )
                  if ( $logger->is_debug() );

                unless (( defined( $data_ref->{$fh_bytes} ) )
                    and ( $data_ref->{$fh_bytes} > 0 ) )
                {

                    $data_ref->{$fh_bytes} =
                      sysread( $fh, $data_ref->{$fh_name},
                        $self->get_buffer_size() );

                }
                else {

                    $logger->info(
                        'Caught part of a record, repeating sysread with offset'
                    ) if ( $logger->is_info() );

              # Like all Perl character operations, length() normally deals in
              # logical characters, not physical bytes. For how many bytes a
              # string encoded as UTF-8 would take up, use
              # "length(Encode::encode_utf8(EXPR))" (you'll have to "use Encode"
              # first). See Encode and perlunicode.
                    my $offset =
                      length( Encode::encode_utf8( $data_ref->{$fh_name} ) );

                    $logger->debug("Offset is $offset")
                      if ( $logger->is_debug() );

                    $data_ref->{$fh_bytes} =
                      sysread( $fh, $data_ref->{$fh_name},
                        $self->get_buffer_size(), $offset );

                }

                unless ( defined( $data_ref->{$fh_bytes} ) ) {

                    $logger->fatal( 'sysread returned an error: ' . $! );

                    $self->_check_child($logger);

                    $logger->logdie( 'sysreading from '
                          . $fh_name
                          . ' returned an unrecoverable error' );

                }
                else {

                    if ( $logger->is_debug() ) {

                        $logger->debug( 'Read '
                              . $data_ref->{$fh_bytes}
                              . ' bytes from '
                              . $fh_name );

                    }

                    if ( $data_ref->{$fh_bytes} == 0 ) {

                        $logger->warn( 'got EOF from ' . fileno($fh) . '?' );
                        $select->remove($fh);
                        next;

                    }

                    unless ( ( $data_ref->{$fh_name} =~ $eol_regex )
                        or ( $data_ref->{$fh_name} =~ $prompt_regex ) )
                    {

                        $logger->debug(
'Buffer data does not ends with CRLF or prompt, needs to read more from handle'
                        );
                        $logger->debug(
                            'Buffer is [' . $data_ref->{$fh_name} . ']' );

                        next;

                    }

                    $self->normalize_eol( \$data_ref->{$fh_name} );

                    if ( $fh == $self->get_read() ) {

# :WORKAROUND:14/08/2013 18:40:46:: necessary to empty the stdout for possible (useless) information hanging in the buffer, but
# this information must be discarded since is from the previous processed command submitted
# :TODO      :14/08/2013 18:41:43:: check why such information is not being recovered in the previous execution
                        $self->_process_stdout( \$data_ref->{$fh_name},
                            \@input_buffer, $logger, $condition )
                          unless ($ignore_output);

                        $data_ref->{$fh_name}  = undef;
                        $data_ref->{$fh_bytes} = 0;

                    }
                    elsif ( $fh == $self->get_error() ) {

                        $self->_process_stderr( \$data_ref->{$fh_name},
                            $logger );

                        $data_ref->{$fh_name}  = undef;
                        $data_ref->{$fh_bytes} = 0;

                    }
                    else {
                        $logger->logdie(
                            'Somehow got a filehandle I dont know about!');
                    }
                }

            }    # end of foreach block

        }    # end of while block

        $data_ref = undef;

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

# :TODO      :16/08/2013 19:03:30:: move this log statement to Siebel::Srvrmgr::Daemon::Action
            if ( $logger->is_debug() ) {

                $logger->debug('Lines from buffer sent for parsing');

                foreach my $line (@input_buffer) {

                    $logger->debug($line);

                }

                $logger->debug('End of lines from buffer sent for parsing');

            }

# :WORKAROUND:16/08/2013 18:54:51:: exceptions from validating output are not being seen
# :TODO      :16/08/2013 18:55:18:: start using TryCatch to use exceptions for known problems
            eval {

                $condition->set_output_used( $action->do( \@input_buffer ) );

            };

            $logger->logdie($@) if ($@);

            $logger->debug( 'Is output used? ' . $condition->is_output_used() )
              if ( $logger->is_debug() );
            @input_buffer = ();

        }
        else {

            $logger->warn(
'The internal buffer is empty: check out if the read_timeout is not too low'
            );

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

sub _create_handle_buffer {

    my $self   = shift;
    my $select = shift;    # IO::Select object
    my $logger = shift;    # Log::Log4perl object

    # to keep data from both handles while looping over them
    my %data;

    foreach my $fh ( $self->get_read(), $self->get_error() ) {

        my $fh_name  = fileno($fh);
        my $fh_bytes = $fh_name . '_bytes';

        $data{$fh_name}  = undef;
        $data{$fh_bytes} = 0;
        $select->add($fh);

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

        my $assert = 'Input record separator is ';

      SWITCH: {

            if ( $/ eq CR ) {
                $logger->debug( $assert . 'CR' );
                last SWITCH;
            }
            if ( $/ eq CRLF ) {
                $logger->debug( $assert . 'CRLF' );
                last SWITCH;
            }
            if ( $/ eq LF ) {
                $logger->debug( $assert . 'LF' );
                last SWITCH;
            }
            else {
                $logger->debug("Unknown input record separator: [$/]");
            }

        }

    }

    return \%data;

}

sub _create_child {

    my $self = shift;

    my $logger = Siebel::Srvrmgr->gimme_logger( ref($self) );
    weaken($logger);

    if ( $self->get_retries() >= $self->get_max_retries() ) {

        $logger->fatal( 'Maximum retries to spawn srvrmgr reached: '
              . $self->get_max_retries() );
        $logger->warn(
'Application will exit with an error return code. Please review log for errors'
        );
        exit(1);

    }

    $logger->logdie( 'Cannot find program ' . $self->get_bin() . ' to execute' )
      unless ( -e $self->get_bin() );

    my $params_ref = $self->_define_params();

    my ( $pid, $write_h, $read_h, $error_h ) = safe_open3($params_ref);
    $self->_set_pid($pid);
    $self->_set_write($write_h);
    $self->_set_read($read_h);
    $self->_set_error($error_h);

    if ( $logger->is_debug() ) {

        $logger->debug( 'Forked srvrmgr with the following parameters: '
              . join( ' ', @{$params_ref} ) );
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
#            $line =~ s/\r$//;

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

    $logger->debug("Raw content is [$$data_ref]") if $logger->is_debug();

    foreach my $line ( split( "\n", $$data_ref ) ) {

        exit if ( $SIG_INT or $SIG_PIPE );

        if ( $logger->is_debug() ) {

            if ( defined($line) ) {

                $logger->debug("Recovered line [$line]");

            }
            else {

                $logger->debug("Recovered line with undefined content");

            }

        }

      SWITCH: {

            if ( $line =~ SIEBEL_ERROR ) {

                $self->_check_error( $line, $logger );
                last SWITCH;

            }

# :TRICKY:29/06/2011 21:23:11:: bufferization in srvrmgr.exe ruins the day: the prompt will never come out unless a little push is given
# :TODO      :03/09/2013 12:11:27:: check if a print with an empty line is not required here
            if ( $line =~ ROWS_RETURNED ) {

                # parsers will consider the lines below
                push( @{$buffer_ref}, $line );
                last SWITCH;

            }

            # prompt was returned, end of output
            # first execution should bring only informations about Siebel
            if ( $line =~ /$prompt_regex/ ) {

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

                }

                push( @{$buffer_ref}, $line );

                last SWITCH;

            }

# no prompt detection, keep reading output from srvrmgr
            else { push( @{$buffer_ref}, $line ); }

        }

    }

}

sub _check_child {

    my $self   = shift;
    my $logger = shift;
    weaken($logger);

    if ( $self->has_pid() ) {

# :WORKAROUND:19/4/2012 19:38:04:: somehow the child process of srvrmgr has to be waited for one second and receive one kill 0 signal before
# it dies when something goes wrong
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

    }    # end of if has_pid
    else {

        return 0;

    }

}

sub _my_cleanup {

    my $self   = shift;
    my $logger = shift();
    weaken($logger);

    if ( $self->has_pid() and ( $self->get_pid() =~ /\d+/ ) ) {

        $self->close_child($logger);

    }
    else {

        if ( $logger->is_info() ) {

            $logger->info( 'No child process to terminate' );

        }

    }

    return 1;

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

    $self->_check_cmd($cmd);
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

Accepts as an optional parameter an instance of a L<Log::Log4perl> for logging messages.

=cut

sub close_child {

    my $self   = shift;
    my $logger = shift;

    my $has_logger = 0;

    if ( ( defined($logger) ) and ( ref($logger) ) ) {

        weaken($logger);
        $has_logger = 1;

    }

    if ( $self->has_pid() ) {

        if ( $has_logger && $logger->is_warn() ) {

            $logger->warn( 'Trying to close child PID ' . $self->get_pid() );

        }

        if (    ( openhandle( $self->get_write() ) )
            and ( not($SIG_PIPE) )
            and ( not($SIG_ALARM) ) )
        {

            $self->_submit_cmd( 'exit', $logger );

            if ( $has_logger && $logger->is_debug() ) {

                $logger->debug('Submitted exit command to srvrmgr');

            }

        }
        else {

            $logger->warn('write_fh is already closed') if ($has_logger);

        }

        for ( 1 .. 4 ) {

            sleep 1;

            if ( kill( 0, $self->get_pid() ) ) {

                $logger->debug('child process is still there');
            }
            else {

                last;

            }

        }

        if ( kill 0, $self->get_pid() ) {

            if ( $has_logger && $logger->is_debug() ) {

                $logger->debug(
                    'srvrmgr is still running, trying waitpid on it');

            }

            my $ret = waitpid( $self->get_pid(), 0 );

          SWITCH: {

                if ( $ret == $self->get_pid() ) {

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

                    last SWITCH;

                }

                if ( $ret == -1 ) {

                    $logger->info(
                        'No such PID ' . $self->get_pid() . ' to kill' )
                      if ( $has_logger && $logger->is_info() );
                    last SWITCH;

                }
                else {

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

            $logger->warn('Child process is already gone')
              if ( $has_logger && $logger->is_warn() );

        }

        $self->clear_pid();
        return 1;

    }
    else {

        $logger->info('Has no child PID available to terminate')
          if ( $has_logger && $logger->is_info() );
        return 0;

    }

}

=pod

=head1 CAVEATS

This class is still considered experimental and should be used with care. Tests with MS Windows (and the nature of doing IPC within the plataform) makes it difficult do use this class in Microsoft OS's.

The C<srvrmgr> program uses buffering, which makes difficult to read the generated output as expected.

=head1 SEE ALSO

=over

=item *

L<IPC::Open3>

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

L<Siebel::Srvrmgr::Daemon::IPC>

=item *

L<https://github.com/lucastheisen/ipc-open3-callback>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>.

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
along with Siebel Monitoring Tools.  If not, see L<http://www.gnu.org/licenses/>.

=cut

__PACKAGE__->meta->make_immutable;

1;

