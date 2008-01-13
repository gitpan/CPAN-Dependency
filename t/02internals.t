use strict;
use Test::More;
use CPAN::Dependency;


plan tests => 53;

# create an object
my $cpandep = undef;
eval { $cpandep = new CPAN::Dependency };
is( $@, ''                                  , "object created"               );
ok( defined $cpandep                        , "object is defined"            );
ok( $cpandep->isa('CPAN::Dependency')       , "object is of expected type"   );
is( ref $cpandep, 'CPAN::Dependency'        , "object is of expected ref"    );

# check that CPANPLUS object is correctly created
ok( defined $cpandep->{backend}                   , "backend object is defined"          );
ok( $cpandep->{backend}->isa('CPANPLUS::Backend') , "backend object is of expected type" );
is( ref $cpandep->{backend}, 'CPANPLUS::Backend'  , "backend object is of expected ref"  );

# check binary options
for my $option (qw(clean_build_dir color debug prefer_bin verbose)) {
    ok( ref $cpandep->can($option)          , "object->can($option)"         );
    $cpandep->$option(1);
    is( $cpandep->{options}{$option}, 1     , "  checking true value"        );
    $cpandep->$option(0);
    is( $cpandep->{options}{$option}, 0     , "  checking false value"       );
}

# check that process() works
my @mods = qw(WWW::Mechanize Maypole Template CPAN::Search::Lite);
$cpandep->process(@mods[0,1]);
is_deeply( $cpandep->{process}, [@mods[0,1]] , "calling process() with two args as list" );
$cpandep->process([@mods[2,3]]);
is_deeply( $cpandep->{process}, [@mods]      , "calling process() with two args as arrayref" );

# check that skip() works (note: skip() accepts module or distribution 
# names but only stores distribution names)
$cpandep->{skip} = {};
my @skip_list = qw(LWP::UserAgent     Net::SSLeay           CGI            Net-Pcap      );
my %expected1 = ('libwww-perl' => 1, 'Net-SSLeay' => 1                                   );
my %expected2 = ( %expected1                             , 'CGI' => 1,    'Net-Pcap' => 1);
$cpandep->skip(@skip_list[0,1]);
is_deeply( $cpandep->{skip}, \%expected1 , "calling skip() with two args as list" );
$cpandep->skip([@skip_list[2,3]]);
is_deeply( $cpandep->{skip}, \%expected2 , "calling skip() with two args as arrayref" );

# now checking that creating an object by passing options to new()
# works as expected
$cpandep = undef;
eval { $cpandep = new CPAN::Dependency verbose => 0, color => 0, debug => 0, prefer_bin => 0, clean_build_dir => 0 };
is( $@, ''                                  , "object created (with boolean options set to 0)" );
ok( defined $cpandep                        , "object is defined"            );
ok( $cpandep->isa('CPAN::Dependency')       , "object is of expected type"   );
is( ref $cpandep, 'CPAN::Dependency'        , "object is of expected ref"    );
for my $option (qw(clean_build_dir color debug prefer_bin verbose)) {
    is( $cpandep->{options}{$option}, 0     , "  checking true value"        );
}

$cpandep = undef;
eval { $cpandep = new CPAN::Dependency verbose => 1, color => 1, debug => 1, prefer_bin => 1, clean_build_dir => 1 };
is( $@, ''                                  , "object created (with boolean options set to 1)" );
ok( defined $cpandep                        , "object is defined"            );
ok( $cpandep->isa('CPAN::Dependency')       , "object is of expected type"   );
is( ref $cpandep, 'CPAN::Dependency'        , "object is of expected ref"    );
for my $option (qw(clean_build_dir color debug prefer_bin verbose)) {
    is( $cpandep->{options}{$option}, 1     , "  checking true value"        );
}

$cpandep = undef;
eval { $cpandep = new CPAN::Dependency process => [ @mods ] };
is( $@, ''                                  , "object created (passing a list of modules to process())" );
ok( defined $cpandep                        , "object is defined"            );
ok( $cpandep->isa('CPAN::Dependency')       , "object is of expected type"   );
is( ref $cpandep, 'CPAN::Dependency'        , "object is of expected ref"    );
is_deeply( $cpandep->{process}, [@mods]    , "checking process() with two args as arrayref" );

$cpandep = undef;
eval { $cpandep = new CPAN::Dependency skip => [ @skip_list ] };
is( $@, ''                                  , "object created (passing a list of modules to process())" );
ok( defined $cpandep                        , "object is defined"            );
ok( $cpandep->isa('CPAN::Dependency')       , "object is of expected type"   );
is( ref $cpandep, 'CPAN::Dependency'        , "object is of expected ref"    );

