use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CPAN::Dependency',
    AUTHOR              => 'Sébastien Aperghis-Tramoni <sebastien@aperghis.net>',
    VERSION_FROM        => 'lib/CPAN/Dependency.pm',
    ABSTRACT_FROM       => 'lib/CPAN/Dependency.pm',
    #EXE_FILES           => [ 'bin/cpandep' ], 
    PL_FILES            => {},
    PREREQ_PM => {
        'CPANPLUS' => '0.050',
        'File::Slurp' => 0,
        'File::Spec' => 0,
        'Module::Depends' => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CPAN-Dependency-*' },
);
