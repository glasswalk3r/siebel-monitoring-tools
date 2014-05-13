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
        'File::BOM'                    => 0.14
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
    ABSTRACT_FROM => 'lib/Siebel/Srvrmgr.pm',    # retrieve abstract from module
    AUTHOR    => 'Alceu Rodrigues de Freitas Junior <arfreitas@cpan.org>',
    'LICENSE' => 'gpl',
);

my_WriteMakefile(%config);

sub my_WriteMakefile
{ #Compatibility code for old versions of EU::MM. Written by Alexandr Ciornii, version 0.23. Added by eumm-upgrade.

    my %params       = @_;
    my $eumm_version = $ExtUtils::MakeMaker::VERSION;
    $eumm_version = eval $eumm_version;
    die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
    die "License not specified" if not exists $params{LICENSE};

    if (    $params{AUTHOR}
        and ref( $params{AUTHOR} ) eq 'ARRAY'
        and $eumm_version < 6.5705 )
    {
        $params{META_ADD}->{author} = $params{AUTHOR};
        $params{AUTHOR} = join( ', ', @{ $params{AUTHOR} } );
    }

    if ( $params{TEST_REQUIRES} and $eumm_version < 6.64 ) {
        $params{BUILD_REQUIRES} =
          { %{ $params{BUILD_REQUIRES} || {} }, %{ $params{TEST_REQUIRES} } };
        delete $params{TEST_REQUIRES};
    }

    if ( $params{BUILD_REQUIRES} and $eumm_version < 6.5503 ) {

        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM} =
          { %{ $params{PREREQ_PM} || {} }, %{ $params{BUILD_REQUIRES} } };
        delete $params{BUILD_REQUIRES};
    }

    delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
    delete $params{MIN_PERL_VERSION}   if $eumm_version < 6.48;

    if ( $eumm_version < 6.46 ) {

        delete $params{META_MERGE};
        delete $params{META_ADD};

    }
    delete $params{LICENSE} if $eumm_version < 6.31;

    WriteMakefile(%params);
}

