package Siebel::Srvrmgr::OS::Unix;

use Moose;
use Proc::ProcessTable;
use namespace::autoclean;
use Set::Tiny;
use File::Copy;
use File::Temp qw(tempfile);
use Carp qw(cluck confess);
use String::BOM qw(strip_bom_from_string);
use Digest::MD5 qw(md5_base64);

=pod

=head1 NAME

Siebel::Srvrmgr::OS::Unix - module to recover information from OS processes of Siebel components

=head1 SYNOPSIS

    use Siebel::Srvrmgr::OS::Unix;
    my $procs = Siebel::Srvrmgr::OS::Unix->new(
        {
            enterprise_log => $enterprise_log,
            cmd_regex      => "^$path_to_siebel_dir",
            parent_regex => 'Created\s(multithreaded\s)?server\sprocess\s\(OS\spid\s\=\s+\d+\s+\)\sfor\s\w+'
        }
    );
    my $procs_ref = $procs->get_procs;
    foreach my $comp_pid( keys( %{$procs_ref} ) ) {

        print 'Component ', $procs_ref->{$comp_pid}->{comp_alias}, ' is using ', $procs_ref->{$comp_pid}->{pctcpu}, "% of CPU now\n";

    }

=head1 DESCRIPTION

This module is a L<Moose> class.

It is responsible to recover information from processes executing on a UNIX-like O.S. and merging that with information of Siebel components.

Details on running processes are recovered from C</proc> directory meanwhile the details about the components are read from the Siebel Enterprise log file. 

This enables one to create a "cheap" (in the sense of not needing to connect to the Siebel Server) component monitor to recover periodic information about CPU, memory, etc, usage by the Siebel 
components.

=head1 ATTRIBUTES

=head2 enterprise_log

Required attribute.

A string of the complete path name to the Siebel enterprise log file.

=cut

has enterprise_log => (
    is       => 'rw',
    isa      => 'Str',
    reader   => 'get_ent_log',
    writer   => 'set_ent_log',
    required => 1
);

=head2 parent_regex

Required attribute.

A string of the regular expression to match the components PID logged in the Siebel Enterprise log file. The regex should match the text in the sixth "column" (considering
that they are separated by a tab character) of a Siebel Enterprise log. Since the Siebel Enterprise may contain different language settings, this parameter is required and 
will depend on the language set.

An example of configuration will help understand. Take your time to review the piece of Enterprise log file below:

    ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	AdminNotify	STARTING	Component is starting up.
    ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	AdminNotify	INITIALIZED	Component has initialized (no spawned procs).
    ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	SvrTaskPersist	STARTING	Component is starting up.
    ServerLog	ProcessCreate	1	0000149754f82575:0	2015-03-05 13:15:41	Created multithreaded server process (OS pid = 	9644	) for SRProc
    ServerLog	ProcessCreate	1	0000149754f82575:0	2015-03-05 13:15:41	Created multithreaded server process (OS pid = 	9645	) for FSMSrvr
    ServerLog	ProcessCreate	1	0000149754f82575:0	2015-03-05 13:15:41	Created multithreaded server process (OS pid = 	9651	) for AdminNotify

In this case, the string should be a regular expression something like C<Created\s(multithreaded)?\sserver\sprocess>.

This attribute is a string, not a compiled regular expression with C<qr>.

=cut

has parent_regex => (
    is       => 'rw',
    isa      => 'Str',
    reader   => 'get_parent_regex',
    writer   => 'set_parent_regex',
    required => 1
);

=head2 cmd_regex

Required attribute.

A string of the regular expression to match the command executed by the Siebel user from the C<cmdline> file in C</proc>.
This usually is the path included in the binary when you check with C<ps -aux> command.

This attribute is a string, not a compiled regular expression with C<qr>.

The amount of processes returned will depend on the regular expression used: one can match anything execute by the Siebel 
OS user or only the processes related to the Siebel components.

=cut

has cmd_regex => (
    is       => 'rw',
    isa      => 'Str',
    reader   => 'get_cmd',
    writer   => 'set_cmd',
    required => 1
);

=head2 mem_limit

Optional attribute.

A integer representing the maximum bytes of RSS a Siebel process might have.

If set together with C<limits_callback>, this class can execute some action when this threshold is exceeded.

=cut

has mem_limit => (
    is      => 'rw',
    isa     => 'Int',
    reader  => 'get_mem_limit',
    writer  => 'set_mem_limit',
    default => 0
);

=head2 cpu_limit

Optional attribute.

A integer representing the maximum CPU percentage a Siebel process might have.

If set together with C<limits_callback>, this class can execute some action when this threshold is exceeded.

=cut

has cpu_limit => (
    is      => 'rw',
    isa     => 'Int',
    reader  => 'get_cpu_limit',
    writer  => 'set_cpu_limit',
    default => 0
);

=head2 limits_callback

Optional attribute.

A code reference that will be executed when one of the attributes C<mem_limit> and C<cpu_limit> threshold is exceeded.

This is useful, for example, with you want to set a alarm or something like that.

The code reference will receive a hash reference as parameter which keys and values will depend on the type of limit triggered:

=over

=item *

memory:

    type  => 'memory'
    rss   => <processes RSS>
    vsz   => <process VSZ>
    pid   => <process id>
    fname => <process fname>,
    cmd   => <process cmndline>

=item *

CPU:

    type  => 'cpu'
    cpu   => <process % of cpu>
    pid   => <process id>
    fname => <process fname>
    cmd   => <process cmndline>

=back

=cut

has limits_callback => (
    is     => 'rw',
    isa    => 'CodeRef',
    reader => 'get_callback',
    writer => 'set_callback'
);

=head2 last_line

The last line read from the Siebel Enterprise log.

The attribute is an integer, and it's definition occurs automatically.

It will be updated internally only if the attribute C<use_last_line> is set to true.

=cut

has last_line => (
    is      => 'ro',
    isa     => 'Int',
    reader  => 'get_last_line',
    writer  => '_set_last_line',
    lazy    => 1,
    builder => '_build_last_line'
);

=head2 use_last_line

A boolean attribute, by default set to false.

If set to true, the attribute C<last_line> will be updated with the last line number read from the Siebel Enterprise log file. One can use this attribute to avoid reading again 
and again the whole Siebel Enterprise log file. More important, that means that the risk to associated a component alias with a long gone process which PID was reused by the O.S.

Of course, by limiting the amount of lines that will be read from the Siebel Enterprise log file, you will need to supply a set of values (PID/component alias) to compare with the most recent
list of processes retrieved from the O.S.

=cut

has use_last_line =>
  ( is => 'ro', isa => 'Bool', reader => 'use_last_line', default => 0 );

=head2 archive

An object instance of a class that uses the L<Moose::Role> L<Siebel::Srvrmgr::OS::Enterprise::Archive>.

=cut

has 'archive' => (
    is     => 'ro',
    does   => 'Siebel::Srvrmgr::OS::Enterprise::Archive',
    reader => 'get_archive'
);

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

A string identifying the character(s) used to separate the fields in the Siebel Enterprise log file is configured.

This attribute is read-only, this class will automatically try to define the EOL being used.

=cut

has fs => (
    is      => 'ro',
    isa     => 'Str',
    reader  => 'get_fs',
    writer  => '_set_fs',
    default => 0
);

=head1 METHODS

=head2 new

To create new instances of Siebel::Srvrmgr::OS::Unix.

The constructor expects a hash reference with the attributes required plus those that are marked as optional.

An important concept (and the reason for this paragraph) is that the reading of the Siebel Enterprise log file might be restricted or not.

In restricted mode, the Siebel Enterprise log file is read once and the already read component aliases is persisted somehow, including the last line of the file read: that will avoid
reading all over the file again, and more important, minimizing association of reused PIDs with component aliases, thus generating incorrect data. For restricted mode it is necessary to pass 
as parameters the attributes C<use_last_line> and C<archive>.

To use "simple" mode, nothing else is necessary. Simple is much simpler to be used, but there is the risk of PIDs reutilization causing invalid data to be generated. For long running monitoring, 
I suggest using restricted mode.

=head2 BUILD

Validates the state of the object during instantiation by checking if the attribute C<archive> is correctly set if C<use_last_line> is set to true.

=cut

sub BUILD {

    my $self = shift;

    confess "must have attribute archive defined if use_last_line is set"
      if ( $self->use_last_line()
        and ( not( defined( $self->get_archive ) ) ) );

}

sub _build_last_line {

    my $self = shift;

    if ( $self->use_last_line() ) {

        $self->_set_last_line( $self->get_archive()->get_last_line() );

    }

}

=head2 get_procs

Searches through C</proc> and the Siebel Enterprise log file and returns an hash reference with the pids as keys and hashes references as values.
For those hash references, the following keys will be available:

=over

=item *

fname: name of the process

=item *

pctcpu: % of server total CPU

=item *

pctmem: % of server total memory

=item *

rss: RSS

=item *

vsz: VSZ

=item *

comp_alias: alias of the Siebel Component. If the PID is not related to a Siebel component process (for example, the process of the Siebel Gateway)
this key value will be "N/A" by default.

=back

The only process informations will be those match C<cmd_regex> and that have C<fname> equal one of the following values:

=over 

=item *

siebmtsh

=item *

siebmtshmw

=item *

siebproc

=item *

siebprocmw

=item *

siebsess

=item *

siebsh

=item *

siebshmw

=back

=cut

sub get_procs {

    my $self = shift;
    my $cmd_regex;

    {

        my $regex = $self->get_cmd;
        $cmd_regex = qr/$regex/;

    }

    my $server_procs = Set::Tiny->new(
        'siebmtsh', 'siebmtshmw', 'siebproc', 'siebprocmw',
        'siebsess', 'siebsh',     'siebshmw'
    );

    my $t = Proc::ProcessTable->new( enable_ttys => 0 );

    my %procs;

    for my $process ( @{ $t->table } ) {

        next unless ( $process->cmndline =~ $cmd_regex );

        # :WORKAROUND:22-03-2015 20:54:51:: forcing conversion to number
        my $pctcpu = $process->pctcpu;
        $pctcpu =~ s/\s//;
        $pctcpu += 0;

        $procs{ $process->pid } = {
            fname  => $process->fname,
            pctcpu => $pctcpu,
            pctmem => ( $process->pctmem + 0 ),
            rss    => ( $process->rss + 0 ),
            vsz    => ( $process->size + 0 )
        };

        if ( $server_procs->has( $process->fname ) ) {

            $procs{ $process->pid }->{comp_alias} = 'unknown';

        }
        else {

            $procs{ $process->pid }->{comp_alias} = 'N/A';

        }

        if ( $self->get_mem_limit > 0 ) {

            if (    ( $process->rss > $self->get_mem_limit )
                and ( defined( $self->get_callback ) ) )
            {

                $self->get_callback->(
                    {
                        type  => 'memory',
                        rss   => $process->rss,
                        vsz   => $process->size,
                        pid   => $process->pid,
                        fname => $process->fname,
                        cmd   => $process->cmndline
                    }
                );

            }

        }

        if ( $self->get_cpu_limit > 0 ) {

            if (    ( $process->pctcpu > $self->get_cpu_limit )
                and ( defined( $self->get_callback ) ) )
            {

                $self->get_callback->(
                    {
                        type  => 'cpu',
                        cpu   => $process->pctcpu,
                        pid   => $process->pid,
                        fname => $process->fname,
                        cmd   => $process->cmndline
                    }
                );

            }

        }

    }

    if ( $self->use_last_line() ) {

        $self->_res_find_pid( \%procs );

    }
    else {

        $self->_find_pid( \%procs );

    }

    return \%procs;

}

# to avoid reading the log file meanwhile the Siebel Server writes to it
sub _read_ent_log {

    my $self     = shift;
    my $template = __PACKAGE__ . '_XXXXXX';
    $template =~ s/\:{2}/_/g;
    my ( $fh, $filename ) = tempfile( $template, UNLINK => 1 );

    copy( $self->get_ent_log, $filename );

    my $header = <$fh>;
    $self->_check_header($header);

    return $fh;

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

sub _update_last_line {

    my $self  = shift;
    my $value = shift;

    $self->get_archive()->set_last_line($value);
    $self->_set_last_line($value);

}

# restrict find the pid by ignoring previous read line from the Siebel Enterprise log file
sub _res_find_pid {

    my $self      = shift;
    my $procs_ref = shift;
    my %comps;

    my $create_regex;

    {

        my $regex = $self->get_parent_regex;
        $create_regex = qr/$regex/;

    }

    my $in = $self->_read_ent_log();
    local $/ = $self->get_eol();
    my $field_delim = $self->get_fs();
    my $last_line   = $self->get_last_line();

    # for performance reasons this loop is duplicated in find_pid
    while ( my $line = <$in> ) {

        next unless ( ( $last_line == 0 ) or ( $. > $last_line ) );
        chomp($line);
        my @parts = split( /$field_delim/, $line );

        next unless ( scalar(@parts) == 7 );

#ServerLog	ProcessCreate	1	0000149754f82575:0	2015-03-05 13:15:41	Created multithreaded server process (OS pid = 	9645	) for FSMSrvr
        if ( $parts[1] eq 'ProcessCreate' ) {

            if ( $parts[5] =~ $create_regex ) {

                $parts[7] =~ s/\s(\w)+\s//;
                $parts[7] =~ tr/)//d;

                # pid => component alias
                $comps{ $parts[6] } = $parts[7];
                next;

            }
            else {

                cluck
"Found a process creation statement but I cannot match parent_regex against '$parts[5]'. Check the regex";

            }

        }

    }

    $self->_update_last_line($.);
    close($in);

# consider that PIDS not available anymore in the /proc are gone and should be removed from the cache
    $self->_delete_old($procs_ref);

    # must keep the pids to add before modifying the procs_ref
    my $to_add = $self->_to_add($procs_ref);
    my $cached = $self->get_archive()->get_set();

    foreach my $proc_pid ( keys( %{$procs_ref} ) ) {

        if ( ( exists( $comps{$proc_pid} ) ) and ( $cached->has($proc_pid) ) ) {

# new reads from log has precendence over the cache, so cache must be also updated
            $procs_ref->{$proc_pid}->{comp_alias} = $comps{$proc_pid};
            $self->get_archive()->remove($proc_pid);
            next;

        }

        if ( exists( $comps{$proc_pid} ) ) {

            $procs_ref->{$proc_pid}->{comp_alias} = $comps{$proc_pid};

        }
        elsif ( $cached->has($proc_pid) ) {

            $procs_ref->{$proc_pid}->{comp_alias} =
              $self->get_archive()->get_alias($proc_pid);

        }
        else {

            $self->_ident_proc( $procs_ref, $proc_pid );

        }

    }

    $self->_add_new( $to_add, $procs_ref );

}

# by nature of how Siebel processes are organized
# hopefully will be invoked just a couple of times so a small performance hit will happen
sub _ident_proc {

    my ( $self, $procs_ref, $pid ) = @_;

    if ( $procs_ref->{$pid}->{fname} eq 'siebmtshmw' ) {

        $procs_ref->{$pid}->{comp_alias} = 'unknown';

    }
    else {

        $procs_ref->{$pid}->{comp_alias} = 'N/A';

    }

}

sub _delete_old {

    my $self      = shift;
    my $procs_ref = shift;
    my $archived  = $self->get_archive->get_set();
    my $new       = Set::Tiny->new( keys( %{$procs_ref} ) );
    my $to_delete = $archived->difference($new);

    foreach my $pid ( $to_delete->members ) {

        $self->get_archive()->remove($pid);

    }

}

sub _to_add {

    my $self      = shift;
    my $procs_ref = shift;
    my $archived  = $self->get_archive->get_set();
    my $new       = Set::Tiny->new( keys( %{$procs_ref} ) );
    return $new->difference($archived);

}

sub _add_new {

    my $self      = shift;
    my $to_add    = shift;
    my $procs_ref = shift;

    foreach my $pid ( $to_add->members ) {

        $self->get_archive->add( $pid, $procs_ref->{$pid}->{comp_alias} );

    }

}

sub _find_pid {

    my $self      = shift;
    my $procs_ref = shift;
    my %comps;

    my $create_regex;

    {

        my $regex = $self->get_parent_regex;
        $create_regex = qr/$regex/;

    }

    my $in = $self->_read_ent_log();
    local $/ = $self->get_eol();
    my $field_delim = $self->get_fs();

    # for performance reasons this loop is duplicated in res_find_pid
    while ( my $line = <$in> ) {

        chomp($line);
        my @parts = split( /$field_delim/, $line );
        next unless ( scalar(@parts) == 7 );

#ServerLog	ProcessCreate	1	0000149754f82575:0	2015-03-05 13:15:41	Created multithreaded server process (OS pid = 	9645	) for FSMSrvr
        if ( $parts[1] eq 'ProcessCreate' ) {

            if ( $parts[5] =~ $create_regex ) {

                $parts[7] =~ s/\s(\w)+\s//;
                $parts[7] =~ tr/)//d;

                # pid => component alias
                $comps{ $parts[6] } = $parts[7];
                next;

            }
            else {

                cluck
"Found a process creation statement but I cannot match parent_regex against '$parts[5]'. Check the regex";

            }

        }

    }

    close($in);

    foreach my $proc_pid ( keys( %{$procs_ref} ) ) {

        if ( exists( $comps{$proc_pid} ) ) {

            $procs_ref->{$proc_pid}->{comp_alias} = $comps{$proc_pid};

        }
        else {

            $self->_ident_proc($procs_ref);

        }

    }

}

=head1 TODO

Most probably this class does too much: reading from a Siebel Enterprise log file should have it's proper class. That should be even more important when different operational systems will have
their respective classes to recover such information.

Additionally, this class might be used as well when recover component information directly querying it from the Siebel Server with L<Siebel::Srvrgrm::Daemon> subclasses.

One might expect this class interface to be changed soon enough.

=head1 SEE ALSO

=over

=item *

L<Moose>

=item *

L<Proc::ProcessTable>

=back

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
