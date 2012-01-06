package Siebel::Srvrmgr::Daemon;

# :TODO:3/1/2012 17:47:12:: this code is totally for Win32 systems, it should be modified to allow subclasses of it so create process could be managed
# from others OS's (e.g., Linux)

=pod
=head1 NAME

Siebel::Srvrmgr::Daemon - Base class for batch sessions of Siebel srvrmgr.exe program

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
                {
                    command => 'list comps',
                    action  => 'Siebel::Srvrmgr::Daemon::Action'
                },
                {
                    command => 'list params',
                    action  => 'Siebel::Srvrmgr::Daemon::Action'
                },
                {
                    command => 'list comp defs for component XXX',
                    action  => 'Siebel::Srvrmgr::Daemon::Action'
                }
            ]
        }
    );

=cut

use warnings;
use strict;
use IPC::Open2;
use Moose;
use namespace::autoclean;
use Siebel::Srvrmgr::Daemon::Condition;
use Siebel::Srvrmgr::Daemon::ActionFactory;
use Siebel::Srvrmgr::ListParser;

use Win32::Process qw(STILL_ACTIVE)
  ;    # :TODO:3/1/2012 16:55:03:: move to a subclass

# both variables below exist to deal with requested termination of the program gracefully
$SIG{INT} = \&terminate;
our $SIG_CAUGHT = 0;

has server     => ( isa => 'Str',        is => 'rw', required => 1 );
has gateway    => ( isa => 'Str',        is => 'rw', required => 1 );
has enterprise => ( isa => 'Str',        is => 'rw', required => 1 );
has user       => ( isa => 'Str',        is => 'rw', required => 1 );
has password   => ( isa => 'Str',        is => 'rw', required => 1 );
has timeout    => ( isa => 'Int',        is => 'rw', default  => 1 );
has commands   => ( isa => 'ArrayRef',   is => 'rw', required => 1 );
has bin        => ( isa => 'Str',        is => 'rw', required => 1 );
has write_fh   => ( isa => 'FileHandle', is => 'ro', writer   => '_set_write' );
has read_fh    => ( isa => 'FileHandle', is => 'ro', writer   => '_set_read' );
has pid        => ( isa => 'Int',        is => 'ro', writer   => '_set_pid' );
has is_infinite   => ( isa => 'Bool', is => 'ro', required => 1 );
has last_exec_cmd => ( isa => 'Str',  is => 'rw', default  => '' );

has cmd_stack => ( isa => 'ArrayRef', is => 'ro', writer => '_set_cmd_stack' );

has params_stack =>
  ( isa => 'ArrayRef', is => 'ro', writer => '_set_params_stack' );

has action_stack =>
  ( isa => 'ArrayRef', is => 'ro', writer => '_set_action_stack' );

# specific code for windows
has exit_code => ( isa => 'Int', is => 'ro', writer => '_set_exit_code' );
has process =>
  ( isa => 'Win32::Process', is => 'ro', writer => '_set_process' );
has win32_timeout => ( isa => 'Int', is => 'ro', default => '5000' );

sub BUILD {

    my $self = shift;

    my $cmds_ref = $self->commands();

    my @cmd;
    my @actions;
    my @params;

    foreach my $cmd_ref ( @{$cmds_ref} ) {    # $cmd_ref is a hash reference

        push( @cmd,     $cmd_ref->{command} );
        push( @actions, $cmd_ref->{action} );
        push( @params,  $cmd_ref->{params} );

    }

    $self->_set_cmd_stack( \@cmd );
    $self->_set_action_stack( \@actions );
    $self->_set_params_stack( \@params );

}

sub run {

    my $self = shift;

    my ( $rdr, $wtr );

# :TRICKY:28/06/2011 19:56:49:: STDERR does not work with IPC::Open3 (STDOUT and STDERR are the same)
    $self->_set_pid(
        open2(
            $rdr,                $wtr, $self->bin(),     '/e',
            $self->enterprise(), '/g', $self->gateway(), '/u',
            $self->user(),       '/p', $self->password()
        )
    );

    $self->_set_write($wtr);
    $self->_set_read($rdr);

    my $process;
    my $exit_code;

# :WORKAROUND:28/06/2011 19:57:24:: necessary to be able to kill the srvrmgr.exe process correctly when the program exists
    Win32::Process::Open( $process, $self->pid(), 0 );

    $process->GetExitCode($exit_code);

    $self->_set_exit_code($exit_code);
    $self->_set_process($process);

    print 'running with PID = ', $self->pid(), ' exit code = ', $exit_code,
      "\n";

# :WARNING:28/06/2011 19:47:26:: reading the output is hanging without an first input
    syswrite $wtr, "\n";

    my $prompt;
    my @input_buffer;

    my $condition = Siebel::Srvrmgr::Daemon::Condition->new(
        {
            is_infinite    => $self->is_infinite(),
            total_commands => scalar( @{ $self->commands() } ),
            cmd_sent       => 0
        }
    );

    do {

        exit if ($SIG_CAUGHT);

      READ: while (<$rdr>) {

            exit if ($SIG_CAUGHT);

            s/\r\n//;

# :TRICKY:29/06/2011 21:23:11:: bufferization in srvrmgr.exe ruins the day: the prompt will never come out unless a little push is given
            if (/^\d+ rows returned\./) {

                # parsers will consider the lines below
                push( @input_buffer, $_ );
                push( @input_buffer, '' );

                syswrite $wtr, "\n";
                last READ;

            }

            # prompt was returned, end of output
            # first execution should bring only informations about Siebel
            if (/^srvrmgr(\:\w+)?>\s$/)
            {    # :TODO:4/1/2012 11:26:28:: make this regex previously compiled

                unless ( defined($prompt) ) {

                    $prompt = $_;

                }

                # no command submitted
                if ( scalar(@input_buffer) < 1 ) {

                    $condition->cmd_sent(0);
                    last READ;

                }
                else {

                    unless (( scalar(@input_buffer) >= 1 )
                        and ( $input_buffer[0] eq $self->last_exec_cmd() )
                        and $condition->cmd_sent() )
                    {

                        $condition->cmd_sent(0);
                        last READ;

                    }

                }

            }
            else {   # no prompt detection, keep reading output from srvrmgr.exe

                push( @input_buffer, $_ );

            }

        }    # end of READ block

        # below is the place for a Action object
        if ( scalar(@input_buffer) >= 1 ) {

            #            push( @input_buffer, $prompt ) if ( defined($prompt) );

# :TRICKY:5/1/2012 17:43:58:: copy params to avoid operations that erases the parameters due passing an array reference and messing with it
            my @params;

            map { push( @params, $_ ) }
              @{ $self->params_stack()->[ $condition->get_cmd_counter() ] };

            my $class =
              $self->action_stack()->[ $condition->get_cmd_counter() ];

            my $action = Siebel::Srvrmgr::Daemon::ActionFactory->create(
                $class,
                {
                    parser => Siebel::Srvrmgr::ListParser->new(
                        { default_prompt => $prompt }
                    ),
                    params => \@params

                }
            );

            $condition->output_used( $action->do( \@input_buffer ) );

            $condition->cmd_sent(0) if ( $condition->output_used() ); # :TODO:6/1/2012 00:03:41:: move this to the Condition class

            @input_buffer = ();

        }

        # begin of session, sending command to the prompt
        unless ( $condition->cmd_sent() ) {

			$condition->add_cmd_counter();

            my $cmd = $self->cmd_stack()->[ $condition->get_cmd_counter() ];

            syswrite $wtr, "$cmd\n";

# srvrmgr.exe of Siebel 7.5.3.17 does not echo command printed to the input file handle
# this is necessary to give a hint to the parser about the command submitted
            push( @input_buffer, $prompt . $cmd );
            $self->last_exec_cmd( $prompt . $cmd );
            $condition->cmd_sent(1);

            sleep( $self->timeout() );

        }

    } while ( $condition->check() );

}

sub DEMOLISH {

    my $self = shift;

    syswrite $self->write_fh(), "exit\n";

    my $rdr =
      $self->read_fh();  # diamond operator does not like method calls inside it

    while (<$rdr>) {

		next if (/^srvrmgr>\s\r\n$/);

        if (/^Disconnecting from server\./) {

            print $_;
            last;

        }
        else {

            print $_;

        }

    }

    close( $self->read_fh() );
    close( $self->write_fh() );

    $self->process()->Wait( $self->win32_timeout() );

    if ( $self->process()->GetExitCode( $self->exit_code() ) ) {

        $self->process()->Kill( $self->exit_code() );
        syswrite STDOUT, "Server manager had to be killed\n";

    }
    else {

        syswrite STDOUT, "Server manager exited without errors\n";

    }

}

sub terminate {

    my ($sig) = @_;
    warn "The Interrupt was caught: <$sig>\n";
    $SIG_CAUGHT = 1;

}

__PACKAGE__->meta->make_immutable;