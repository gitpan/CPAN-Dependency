use strict;
use Test::More;
use Test::Deep;
use File::Temp qw(:POSIX);
use YAML qw(LoadFile);
BEGIN { plan tests => 92 }
use CPAN::Dependency;

# create an object
my $cpandep = undef;
eval { $cpandep = new CPAN::Dependency };
is( $@, ''                                  , "object created"               );
ok( defined $cpandep                        , "object is defined"            );
ok( $cpandep->isa('CPAN::Dependency')       , "object is of expected type"   );
is( ref $cpandep, 'CPAN::Dependency'        , "object is of expected ref"    );

# Checking that the whole thing works as expected. We'll ask the dependencies 
# of several distributions then check that the information are what we know
my @mods = qw(
    WWW::Mechanize  Maypole  Template  CPAN::Search::Lite  Net::Pcap  SVK  Test::Class
);
my %dists = (
    'WWW::Mechanize' => 'WWW-Mechanize', 
    'Maypole' => 'Maypole', 
    'Template' => 'Template-Toolki', 
    'CPAN::Search::Lite' => 'CPAN-Search-Lite', 
    'Net::Pcap' => 'Net-Pcap', 
    'SVK' => 'SVK', 
    'Test::Class' => 'Test-Class', 
);
my %prereqs = (
    'CPAN-Search-Lite' => {
        author => 'Randy Kobes', 
        cpanid => 'RKOBES', 
        prereqs => {
            'AI-Categorizer' => 1, 
            'Archive-Tar' => 1, 
            'Archive-Zip' => 1, 
            'CPAN-DistnameInfo' => 1, 
            'Config-IniFiles' => 1, 
            'DBD-mysql' => 1, 
            'File-Temp' => 1, 
            'IO-Zlib' => 1, 
            'Lingua-Stem' => 1, 
            'Lingua-StopWords' => 1, 
            'PathTools' => 1, 
            'Pod-Parser' => 1, 
            'Sort-Versions' => 1, 
            'XML-Parser' => 1, 
            'YAML' => 1, 
            'libwww-perl' => 1, 
            'txt2html' => 1, 
        }, 
        used_by => ignore(), 
        score => 0, 
    }, 
    Maypole => {
        author => 'Simon Flack', 
        cpanid => 'SIMONFLK', 
        prereqs => {
            'Cgi-Simple' => 1, 
            'CGI-Untaint' => 1, 
            'Class-DBI' => 1, 
            'Class-DBI-AbstractSearch' => 1, 
            'Class-DBI-AsForm' => 1, 
            'Class-DBI-FromCGI' => 1, 
            'Class-DBI-Loader' => 1, 
            'Class-DBI-Loader-Relationship' => 1, 
            'Class-DBI-Pager' => 1, 
            'Class-DBI-Plugin-RetrieveAll' => 1, 
            'Class-DBI-SQLite' => 1, 
            'Template-Plugin-Class' => 1, 
            'Template-Toolkit' => 1, 
            'Test-MockModule' => 0, 
            'UNIVERSAL-exports' => 1, 
            'UNIVERSAL-moniker' => 1, 
            'URI' => 1, 
            'libwww-perl' => 1, 
        }, 
        used_by => ignore(), 
        score => 0, 
    }, 
    'Net-Pcap' => {
        author => 'Tim Potter', 
        cpanid => 'TIMPOTTER', 
        prereqs => {}, 
        used_by => ignore(), 
        score => 0, 
    }, 
    SVK => {
        author => 'Chia-liang Kao', 
        cpanid => 'CLKAO', 
        prereqs => {
            'Algorithm-Annotate' => 0, 
            'Algorithm-Diff' => 1, 
            'Class-Autouse' => 1, 
            'Clone' => 1, 
            'Data-Hierarchy' => 0, 
            'File-Temp' => 1, 
            'File-Type' => 1, 
            'IO-Digest' => 0, 
            'PerlIO-eol' => 1, 
            'PerlIO-via-dynamic' => 0, 
            'PerlIO-via-symlink' => 0, 
            'Pod-Escapes' => 1, 
            'Pod-Simple' => 1, 
            'Regexp-Shellish' => 1, 
            'SVN-Mirror' => 0, 
            'SVN-Simple' => 0, 
            'TimeDate' => 1, 
            'URI' => 1, 
            'YAML' => 1, 
        }, 
        used_by => ignore(), 
        score => 0, 
    }, 
    'Test-Class' => {
        author => 'Adrian Howard', 
        cpanid => 'ADIE', 
        prereqs => {}, 
        used_by => ignore(), 
        score => 0, 
    }, 
    'Template-Toolkit' => {
        author => 'Andy Wardley', 
        cpanid => 'ABW', 
        prereqs => {
            'AppConfig' => 0, 
            'PathTools' => 1, 
        }, 
        used_by => ignore(), 
        score => 0, 
    }, 
    'WWW-Mechanize' => {
        author => 'Andy Lester', 
        cpanid => 'PETDANCE', 
        prereqs => {
            'libwww-perl' => 1, 
            'File-Temp' => 1, 
            'HTML-Parser' => 1, 
            'Pod-Parser' => 1, 
            'Test-Simple' => 1, 
            'URI' => 1, 
        }, 
        used_by => ignore(), 
        score => 0, 
    }, 
);

$cpandep->verbose(0);
$cpandep->debug(0);

for my $mod (@mods) {
    my $dist = $dists{$mod};
    $cpandep->process($mod);
    eval { $cpandep->run };
    is( $@, '', "processing $mod" );
    cmp_deeply( $cpandep->deps_by_dists->{$dist}, $prereqs{$dist}, "checking information for $mod" )
}

# calculate the score of each distribution
eval { $cpandep->calculate_score };
is( $@, '', "calculate_score()" );

is( $cpandep->deps_by_dists->{'Test-Simple'}{score}, '1', "score of Test-Simple" );
is( $cpandep->deps_by_dists->{'URI'        }{score}, '3', "score of URI" );
is( $cpandep->deps_by_dists->{'libwww-perl'}{score}, '3', "score of libwww-perl" );

my %score = ();
eval { %score = $cpandep->score_by_dists };
is( $@, '', "score_by_dists()" );

for my $dist (keys %score) {
    is( $score{$dist}, $cpandep->deps_by_dists->{$dist}{score}, "checking score of $dist" );
}

# saving the dependencies tree to the disk
my $file = tmpnam();
eval { $cpandep->save_deps_tree(file => $file) };
is( $@, '', "save_deps_tree()" );
ok( -f $file, "file exists" );

my $deps = LoadFile($file);
cmp_deeply( $deps, $cpandep->deps_by_dists, "saved file has the same data as object" );

# loading the previously saved tree in a new object
my $cpandep2 = undef;
eval { $cpandep2 = $cpandep->new };
is( $@, ''                                  , "object created"               );
ok( defined $cpandep                        , "object is defined"            );
ok( $cpandep->isa('CPAN::Dependency')       , "object is of expected type"   );
is( ref $cpandep, 'CPAN::Dependency'        , "object is of expected ref"    );

eval { $cpandep2->load_deps_tree(file => $file) };
is( $@, '', "load_deps_tree()" );
cmp_deeply( $cpandep2->deps_by_dists, $deps, "new object has the same data as saved file" );
cmp_deeply( $cpandep2->deps_by_dists, $cpandep->deps_by_dists, "new object has the same data as previous object" );

