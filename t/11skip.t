use strict;
use Test::More;
use Test::Deep;
use File::Temp qw(:POSIX);
use YAML qw(LoadFile);
BEGIN { plan tests => 29 }
use CPAN::Dependency;

# create an object
my $cpandep = undef;
eval { $cpandep = new CPAN::Dependency };
is( $@, ''                                  , "object created"               );
ok( defined $cpandep                        , "object is defined"            );
ok( $cpandep->isa('CPAN::Dependency')       , "object is of expected type"   );
is( ref $cpandep, 'CPAN::Dependency'        , "object is of expected ref"    );

my @bundles = qw(
    Bundle::CPANPLUS  Bundle::Math  Bundle::Net::LDAP  Bundle::Phalanx100
);
my @core = qw(
    Carp  Class::Struct  Fcntl  File::Basename  File::Copy  File::Find
    Getopt::Std  IPC::Open3  Math::Trig  Net::hostent  POSIX  Socket
    Sys::Hostname  Sys::Syslog  Term::ReadLine  Text::ParseWords
    Thread  Tie::Array  Tie::Handle  Tie::Hash  Tie::Scalar
);
my %dists = (
    'Bundle::CPANPLUS' => 'Bundle-CPANPLUS', 
    'Bundle::Math' => 'Bundle-Math', 
    'Bundle::Net::LDAP' => 'Bundle-Net-LDAP', 
    'Bundle::Phalanx100' => 'Bundle-Phalanx', 
);
map { $dists{$_} = 'perl' } @core;

# check that bundles are correctly skipped
$cpandep->process(@bundles);
$cpandep->run;
for my $dist (@dists{@bundles}) {
    ok( not exists $cpandep->{prereqs}{$dist} );
}


# check that core modules are correctly skipped
$cpandep->process(@core);
$cpandep->run;
for my $mod (@core) {
    ok( not exists $cpandep->{prereqs}{$dists{$mod}} );
}

