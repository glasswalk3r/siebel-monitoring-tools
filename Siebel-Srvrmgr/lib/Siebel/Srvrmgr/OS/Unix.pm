package Siebel::Srvrmgr::OS::Unix;

use Moose;
use Proc::ProcessTable;
use namespace::autoclean;

#EnterpriseLogFile: /tcfs12/siebel/81/siebsrvr/enterprises/tcfs12/vmsodcfst004/log/tcfs12.vmsodcfst004.log

has enterprise_log => (
    is       => 'rw',
    isa      => 'Str',
    reader   => 'get_ent_log',
    writer   => 'set_ent_log',
    required => 1
);

#SearchEnterpriseRegex: Se\sha\screado\sun\sproceso\sservidor
has search_regex => (
    is       => 'rw',
    isa      => 'Str',
    reader   => 'get_search',
    writer   => 'set_search',
    required => 1
);

has cmd_regex => (
    is       => 'rw',
    isa      => 'Str',
    reader   => 'get_cmd',
    writer   => 'set_cmd',
    required => 1
);

has mem_limit => (
    is      => 'rw',
    isa     => 'Int',
    reader  => 'get_mem_limit',
    writer  => 'set_mem_limit',
    default => 0
);
has cpu_limit => (
    is      => 'rw',
    isa     => 'Int',
    reader  => 'get_cpu_limit',
    writer  => 'set_cpu_limit',
    default => 0
);
has limits_callback => (
    is     => 'rw',
    isa    => 'CodeRef',
    reader => 'run_callback',
    writer => 'set_callback'
);

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

        $procs{ $process->pid } = {
            fname  => $process->fname,
            pctcpu => $process->pctcpu,
            pctmem => $process->pctmem,
            rss    => $process->rss,
            vsz    => $process->size
        };

        if ( $self->get_mem_limit > 0 ) {

            if (    ( $process->rss > $self->get_mem_limit )
                and ( defined( $self->run_callback ) ) )
            {

                $self->run_callback->(
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
                and ( defined( $self->run_callback ) ) )
            {

                $self->run_callback->(
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

    return \%procs;

}

sub find_pid {

    my $self = shift;
    my %comps;

    my $create_regex;

    {

        my $regex = $self->get_search;
        $create_regex = qr/$regex/;

    }

    local $/ = "\015\012";

    open( my $in, '<', $self->get_ent_log )
      or die( 'Cannot read ' . $self->get_ent_log . ': $!' );

    while ( my $line = <$in> ) {

        if ( $line =~ $create_regex ) {

            chomp($line);
            my @parts = split( /\t/, $line );
            $parts[7] =~ s/\s(\w)+\s//;
            $parts[7] =~ tr/)//d;

            # component alias => pid
            $comps{ $parts[7] } = $parts[6];

        }

    }

    close($in);

    return \%comps;

}

__PACKAGE__->meta->make_immutable;
