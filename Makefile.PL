use 5.010001;
use ExtUtils::MakeMaker;

my %config = (
    NAME         => 'Siebel::Srvrmgr',
    VERSION_FROM => 'lib/Siebel/Srvrmgr.pm',    # finds $VERSION
    PREREQ_PM    => {
        Carp                         => 1.04,
        namespace::autoclean         => 0.13,
        Moose                        => 2.0401,
        FSA::Rules                   => 0.29,
        MooseX::Storage              => 0.30,
        Moose::Util::TypeConstraints => 2.0402,
        MooseX::Params::Validate     => 0.15
    },
    META_MERGE => {
        resources => {
            license  => 'http://www.gnu.org/licenses/old-licenses/gpl-2.0.html',
            homepage => 'http://code.google.com/p/siebel-monitoring-tools/',
            bugtracker =>
              'http://code.google.com/p/siebel-monitoring-tools/issues/list',
            repository =>
              'http://code.google.com/p/siebel-monitoring-tools/source/browse/'
        },
    },
    LICENSE => 'GNU General Public License (GPL)',

    NO_META => 1,
    dist    => { SUFFIX => '.gz', COMPRESS => 'gzip --best' },
    (
        $] >= 5.010001
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM =>
              'lib/Siebel/Srvrmgr.pm',    # retrieve abstract from module
            AUTHOR => 'Alceu Rodrigues de Freitas Junior <arfreitas@cpan.org>'
          )
        : ()
    ),
);

