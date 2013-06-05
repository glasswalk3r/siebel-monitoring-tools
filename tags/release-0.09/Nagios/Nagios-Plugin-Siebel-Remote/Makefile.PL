use 5.010;
use warnings;
use strict;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME     => 'Nagios::Plugin::Siebel::Remote',
    ABSTRACT => 'A Nagios plugin to monitor Siebel Remote pending transactions',
    VERSION  => 0.01,
    NO_MYMETA => 1,
    PREREQ_PM => {
        'Config::Tiny'   => 2.14,
        'DBD::ODBC'      => 1.43,
        'DBI'            => 1.623,
        'Nagios::Plugin' => 0.36
    },
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            AUTHOR => 'Alceu Rodrigues de Freitas Junior <arfreitas@cpan.org>'
          )
        : ()
    ),
    EXE_FILES => ['siebrem.pl'],
    LICENSE   => 'gpl'
);
