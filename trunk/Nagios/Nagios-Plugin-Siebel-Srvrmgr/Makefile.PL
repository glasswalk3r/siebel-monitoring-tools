use lib 'inc';
use Devel::AssertOS qw(Linux AIX Solaris HPUX MSWin32);
use 5.008009;
use warnings;
use strict;
use ExtUtils::MakeMaker;

my %config = (
    NAME             => 'Nagios::Plugin::Siebel::Srvrmgr',
    VERSION_FROM     => 'lib/Nagios/Plugin/Siebel/Srvrmgr.pm',  # finds $VERSION
    MIN_PERL_VERSION => 5.008009,
    PREREQ_PM        => {
        'Siebel::Srvrmgr' => 0.10,
        'RPC::XML'        => 1.56,
        'YAML::Syck'      => 1.27,
        'CHI'             => 0.58,
        'TryCatch'        => 1.003002
    },
    EXE_FILES  => [],
    META_MERGE => {
        resources => {
            license  => 'http://www.gnu.org/licenses/gpl.txt',
            homepage => 'http://code.google.com/p/siebel-monitoring-tools/',
            bugtracker =>
              'http://code.google.com/p/siebel-monitoring-tools/issues/list',
            repository =>
              'http://code.google.com/p/siebel-monitoring-tools/source/browse/'
        },
    },
    dist => { SUFFIX => '.gz', COMPRESS => 'gzip --best' },
    (
        $] >= 5.010
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM => 'lib/Nagios/Plugin/Siebel/Srvrmgr.pm'
            ,    # retrieve abstract from module
            AUTHOR => 'Alceu Rodrigues de Freitas Junior <arfreitas@cpan.org>'
          )
        : ()
    ),
    NO_MYMETA => 1,
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002 ? ( 'LICENSE' => 'gpl', ) : () )
);

WriteMakefile(%config);
