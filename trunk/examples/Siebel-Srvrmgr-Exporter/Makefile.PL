use 5.016003;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Siebel::Srvrmgr::Exporter',
    VERSION_FROM => 'lib/Siebel/Srvrmgr/Exporter.pm',    # finds $VERSION
    PREREQ_PM => { 'Siebel::Srvrmgr' => 0.09, 'Term::Pulse' => 0.04 },
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM =>
              'lib/Siebel/Srvrmgr/Exporter.pm',  # retrieve abstract from module
            AUTHOR => 'Alceu Rodrigues de Freitas Junior <arfreitas@cpan.org>'
          )
        : ()
    ),
    BUILD_REQUIRES => {
        'Test::Pod'           => 1.22,
        'Test::Pod::Coverage' => 1.08
    },
    EXE_FILES  => ['export_comps.pl'],
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
    NO_MYMETA => 1,
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002 ? ( 'LICENSE' => 'gpl', ) : () ),
    dist => { SUFFIX => '.gz', COMPRESS => 'gzip --best' }
);
