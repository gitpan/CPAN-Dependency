use strict;
use Test::More;
use Test::Deep;
BEGIN { plan tests => 21 }
use CPAN::Dependency;

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
for my $option (qw(color debug prefer_bin verbose)) {
    ok( ref $cpandep->can($option)          , "object->can($option)"         );
    $cpandep->$option(1);
    is( $cpandep->{options}{$option}, 1     , "  checking true value"        );
    $cpandep->$option(0);
    is( $cpandep->{options}{$option}, 0     , "  checking false value"       );
}

# check that these process() works
my @mods = qw(WWW::Mechanize Maypole Template CPAN::Search::Lite);
$cpandep->process(@mods[0,1]);
cmp_deeply( $cpandep->{process}, [@mods[0,1]] , "calling process() with two args as list" );
$cpandep->process([@mods[2,3]]);
cmp_deeply( $cpandep->{process}, [@mods]      , "calling process() with two args as arrayref" );
