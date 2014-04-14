use lib 'inc';
use Devel::AssertOS qw(Linux AIX Solaris HPUX MSWin32);
use 5.008009;
use warnings;
use strict;
use ExtUtils::MakeMaker;

my %config = (
    NAME             => 'Siebel::Srvrmgr',
    VERSION_FROM     => 'lib/Siebel/Srvrmgr.pm',    # finds $VERSION
    MIN_PERL_VERSION => 5.008009, 
    PREREQ_PM        => {
        'namespace::autoclean'         => 0.13,
        'Moose'                        => 2.0401,
        'FSA::Rules'                   => 0.32,
        'MooseX::Storage'              => 0.33,
        'Moose::Util::TypeConstraints' => 2.0402,
        'MooseX::AbstractFactory'      => 0.004000,
        'MooseX::Singleton'            => 0.27,
        'MooseX::FollowPBP'            => 0.05,
        'Log::Log4perl'                => 1.41,
        'YAML::Syck'                   => 1.25,
    },
    TEST_REQUIRES => {
        'Test::Most'               => 0.25,
        'Test::Pod'                => 1.22,
        'Test::Pod::Coverage'      => 1.08,
        'Test::Class'              => 0.36,
        'Test::Moose'              => 2.0801,
        'Class::Data::Inheritable' => 0.08,
        'Config::Tiny'             => 2.14,
    },
    EXE_FILES  => ['srvrmgr-mock.pl'],
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
            ABSTRACT_FROM =>
              'lib/Siebel/Srvrmgr.pm',    # retrieve abstract from module
            AUTHOR => 'Alceu Rodrigues de Freitas Junior <arfreitas@cpan.org>'
          )
        : ()
    ),
    NO_MYMETA => 1,
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002 ? ( 'LICENSE' => 'gpl', ) : () )
);

WriteMakefile(%config);
