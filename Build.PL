use strict;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CPAN::Dependency',
    license             => 'perl',
    dist_author         => 'Sébastien Aperghis-Tramoni <sebastien@aperghis.net>',
    dist_version_from   => 'lib/CPAN/Dependency.pm',
    requires => {
        'CPANPLUS' => '0.053',
        'DBI' => '1.0',
        'DBD::SQLite2' => 0,
        'File::Slurp' => 0,
        'File::Spec' => 0,
        'YAML' => 0,
    },
    build_requires => {
        'Test::Deep' => 0,
        'Test::More' => 0,
        'Test::Warn' => 0,
    },
    add_to_cleanup      => [ 'CPAN-Dependency-*' ],
);

$builder->create_build_script();
