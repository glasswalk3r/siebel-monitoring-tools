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
        MooseX::Params::Validate     => 0.15,
        MooseX::AbstractFactory      => 0.004000,
        MooseX::Singleton            => 0.27,
        MooseX::FollowPBP            => 0.05
    },
    BUILD_REQUIRES => {
        Test::Exception     => 0.27,
        Test::Most          => 0.25,
        Test::Pod           => 1.22,
        Test::Pod::Coverage => 1.08,
        Test::Output        => 1.01,
        Test::Class         => 0.36
    },
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
    LICENSE => 'GNU General Public License Version 3 (GPL v3)',
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
    NO_MYMETA => 1
);

WriteMakefile(%config);
