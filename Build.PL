use strict;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CPAN::Dependency',
    license             => 'perl',
    dist_author         => 'Sébastien Aperghis-Tramoni <sebastien@aperghis.net>',
    dist_version_from   => 'lib/CPAN/Dependency.pm',
    #script_files        => [ 'bin/cpandep' ], 
    requires => {
        'CPANPLUS' => '0.051',
        'File::Slurp' => 0,
        'File::Spec' => 0,
        'File::Temp' => 0,
        'Test::Deep' => 0,
        'Test::More' => 0,
        'YAML' => 0,
    },
    add_to_cleanup      => [ 'CPAN-Dependency-*' ],
);

$builder->create_build_script();
