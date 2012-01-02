package Siebel::Srvrmgr::Daemon;

use warnings;
use strict;
use IPC::Open2;
use Moose;
use namespace::autoclean;
use Siebel::Srvrmgr::ListParser;
use Siebel::Srvrmgr::Daemon::Condition;
use Siebel::Srvrmgr::Daemon::ActionFactory;

$SIG{INT} = \&terminate;

our $SIG_CAUGHT = 0;

has server     => ( isa => 'Str', is => 'rw', required => 1 );
has gateway    => ( isa => 'Str', is => 'rw', required => 1 );
has enterprise => ( isa => 'Str', is => 'rw', required => 1 );
has user       => ( isa => 'Str', is => 'rw', required => 1 );
has password   => ( isa => 'Str', is => 'rw', required => 1 );
has timeout    => ( isa => 'Int', is => 'rw', default  => 1 );
has commands => ( isa => 'ArrayRef', => 'rw', required => 1 );
has bin      => ( isa => 'Str',        is => 'rw', required => 1 );
has write_fh => ( isa => 'FileHandle', is => 'ro', writer   => '_set_write' );
has read_fh  => ( isa => 'FileHandle', is => 'ro', writer   => '_set_read' );
has pid      => ( isa => 'Int',        is => 'ro', writer   => '_set_pid' );
has is_infinite => ( isa => 'Bool', is => 'ro', required => 1 );

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
#Win32::Process::Open( $process, $pid, 0 );
#
#$process->GetExitCode($exit_code);
#
#print "$srvrmgr running with PID = $pid, exit code = $exit_code\n";

# :WARNING:28/06/2011 19:47:26:: reading the output is hanging without an first input
    syswrite $wtr, "\n";

    my $prompt;
    my $command_sent = 0;
    my @input_buffer;

    my $condition = Siebel::Srvrmgr::Daemon::Condition(
        {
            is_infinite    => $self->is_infinite(),
            total_commands => scalar( @{ $self->commands() } )
        }
    );

    while ( $condition->check() ) {

      READ: while (<$rdr>) {

            s/\r\n//;

            # prompt was returned, end of output
            # first execution should bring only informations about Siebel
            if (/^srvrmgr(\:\w+)?>\s$/) {

                unless ( defined($prompt) ) {

                    $prompt = $_;

# :TODO:30/06/2011 15:26:28:: Siebel::Srvmgr::Parser should be a singleton object
                    my $parser = Siebel::Srvrmgr::ListParser->new(
                        { default_prompt => $prompt } );

                }

                # do not add the prompt if there is no meaningful output to read
                if (    ( scalar(@input_buffer) > 1 )
                    and ( defined($prompt) ) )
                {

                    push( @input_buffer, $prompt );

                }
                else {

                    last READ;
                }

				# below is the place for a Action object

                # calling the parser
                #            $parser->parse( \@input_buffer );

                #            print $temp Dumper($parser);
                #            print 'Parsed ', $parser->count_parsed(), "\n";
                print "******\n";
                @input_buffer = ();
                $command_sent = 0;

                # prompt detection avoids reading the output forever
                last READ;

            }

            push( @input_buffer, $_ );

# :TRICKY:29/06/2011 21:23:11:: bufferization in srvrmgr.exe ruins the day: the prompt will never come out unless a little push is given
            syswrite $wtr, "\n";

        }

# begin of session, sending command to the prompt
# srvrmgr.exe of Siebel 7.5.3.17 does not echo command printed to the input file handle
        unless ($command_sent) {

            my $cmd = $self->commands()->[ $condition->cmd_counter() ]->{command};  # :TODO:2/1/2012 20:45:33:: too many refs, should change how the object stores commands and actions

            push( @input_buffer, ( $prompt . $cmd ) );
            syswrite $wtr, "$cmd\n";
            $command_sent = 1;

            sleep( $self->timeout() );

        }

    }
}

sub DEMOLISH {

    my $self = shift;

    close( $self->read_fh() );
    syswrite $self->write_fh(), "exit\n";
    close( $self->write_fh() );

    #    $process->Wait($timeout);
    #
    #    if ( $process->GetExitCode($exit_code) eq 'STILL_ACTIVE' ) {
    #
    #        $process->Kill($exit_code);
    #        warn "Server manager had to be killed\n";
    #
    #    }
    #    else {
    #
    #        print "Server manager exited without errors\n";
    #
    #    }

    exit(0);

}

sub terminate {

    my ($sig) = @_;
    warn "The Interrupt was caught: <$sig>\n";
    $SIG_CAUGHT = 1;

}

__PACKAGE__->meta->make_immutable;
