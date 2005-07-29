use strict;
use ExtUtils::MakeMaker;
eval 'use ExtUtils::MakeMaker::Coverage';

WriteMakefile(
    NAME                => 'CPAN::Dependency',
    AUTHOR              => 'Sébastien Aperghis-Tramoni <sebastien@aperghis.net>',
    VERSION_FROM        => 'lib/CPAN/Dependency.pm',
    ABSTRACT_FROM       => 'lib/CPAN/Dependency.pm',
    PREREQ_PM => {
        'CPANPLUS' => '0.053',
        'DBI' => '1.0',
        'DBD::SQLite2' => 0,
        'File::Slurp' => 0,
        'File::Spec' => 0,
        'Test::Deep' => 0,
        'Test::More' => 0,
        'Test::Warn' => 0,
        'YAML' => 0,
    },
    PL_FILES            => {},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CPAN-Dependency-*' },
);
