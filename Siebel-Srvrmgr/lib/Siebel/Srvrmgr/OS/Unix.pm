package Siebel::Srvrmgr::OS::Unix;

use Moose;
use Proc::ProcessTable;
use namespace::autoclean;

=pod

=head1 NAME

Siebel::Srvrmgr::OS::Unix - module to recover information from OS processes of Siebel components

=head1 SYNOPSIS

    use Siebel::Srvrmgr::OS::Unix;
    my $procs = Siebel::Srvrmgr::OS::Unix->new(
        {
            enterprise_log => $enterprise_log,
            cmd_regex      => "^$path_to_siebel_dir",
            parent_regex =>
'Created\s(multithreaded\s)?server\sprocess\s\(OS\spid\s\=\s+\d+\s+\)\sfor\s\w+'
        }
    );
	my $procs_ref = $procs->get_procs;
	foreach my $comp_pid(keys(%{$procs_ref})) {

		print 'Component ', $procs_ref->{$comp_pid}->{comp_alias}, ' is using ', $procs_ref->{$comp_pid}->{pctcpu}, "% of CPU now\n";

	}

=head1 DESCRIPTION

This module is a L<Moose> class.

It is responsible to recover information from a UNIX-like operation system to be able to merge with information
regarding Siebel components.

Any instance of this class must represent the processes of a single Siebel Server and will recover processes 
information from C</proc> directory.

Additionally, this class has a method to search the Siebel enterprise log file for processes information as well.

=head1 ATTRIBUTES

=head2 enterprise_log

Required attribute.
A string of the complete pathname to the Siebel enterprise log file.

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

A string of the regular expression to match if the process recovered from the enterprise log file has children or not.

Since the enterprise may contain different language settings, this parameter is required and will depend on the language set.

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

=head1 METHODS

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

comp_alias: alias of the Siebel Component

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

    my %valid_proc_name = (
        siebmtsh   => 0,
        siebmtshmw => 0,
        siebproc   => 0,
        siebprocmw => 0,
        siebsess   => 0,
        siebsh     => 0,
        siebshmw   => 0
    );

    my $t = Proc::ProcessTable->new( enable_ttys => 0 );

    my %procs;

    for my $process ( @{ $t->table } ) {

        next
          unless ( exists( $valid_proc_name{ $process->fname } )
            and ( $process->cmndline =~ $cmd_regex ) );

        # :WORKAROUND:22-03-2015 20:54:51:: forcing convertion to number
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

    $self->_find_pid( \%procs );

    return \%procs;

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

    local $/ = "\015\012";

    open( my $in, '<', $self->get_ent_log )
      or die( 'Cannot read ' . $self->get_ent_log . ': $!' );

    while ( my $line = <$in> ) {

        chomp($line);

        if ( $line =~ $create_regex ) {

            my @parts = split( /\t/, $line );
            $parts[7] =~ s/\s(\w)+\s//;
            $parts[7] =~ tr/)//d;

            # pid => component alias
			$comps{$parts[6]} = $parts[7];

        }

    }

    close($in);

    foreach my $proc_pid ( keys( %{$procs_ref} ) ) {

        if ( exists( $comps{$proc_pid} ) ) {

            $procs_ref->{$proc_pid}->{comp_alias} = $comps{$proc_pid};

        }

    }

}

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
