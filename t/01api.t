use strict;
use Test;
BEGIN { plan tests => 39 }
use CPAN::Dependency;

# check that the following functions are available
ok( exists &CPAN::Dependency::new                         );
ok( exists &CPAN::Dependency::process                     );
ok( exists &CPAN::Dependency::skip                        );
ok( exists &CPAN::Dependency::run                         );
ok( exists &CPAN::Dependency::calculate_score             );
ok( exists &CPAN::Dependency::deps_by_dists               );
ok( exists &CPAN::Dependency::score_by_dists              );
ok( exists &CPAN::Dependency::save_deps_tree              );
ok( exists &CPAN::Dependency::load_deps_tree              );
ok( exists &CPAN::Dependency::load_cpants_db              );
ok( exists &CPAN::Dependency::_tree_walk                  );
ok( exists &CPAN::Dependency::_vprint                     );
ok( exists &CPAN::Dependency::clean_build_dir             );
ok( exists &CPAN::Dependency::color                       );
ok( exists &CPAN::Dependency::debug                       );
ok( exists &CPAN::Dependency::verbose                     );
ok( exists &CPAN::Dependency::prefer_bin                  );

# create an object
my $cpandep = undef;
eval { $cpandep = new CPAN::Dependency };
ok( $@, ''                                                );
ok( defined $cpandep                                      );
ok( $cpandep->isa('CPAN::Dependency')                     );
ok( ref $cpandep, 'CPAN::Dependency'                      );

# check that the following object methods are available
ok( ref $cpandep->can('new')                              );
ok( ref $cpandep->can('process')                          );
ok( ref $cpandep->can('skip')                             );
ok( ref $cpandep->can('run')                              );
ok( ref $cpandep->can('calculate_score')                  );
ok( ref $cpandep->can('deps_by_dists')                    );
ok( ref $cpandep->can('score_by_dists')                   );
ok( ref $cpandep->can('save_deps_tree')                   );
ok( ref $cpandep->can('load_deps_tree')                   );
ok( ref $cpandep->can('load_cpants_db')                   );
ok( ref $cpandep->can('_tree_walk')                       );
ok( ref $cpandep->can('_vprint')                          );
ok( ref $cpandep->can('_vprintf')                         );
ok( ref $cpandep->can('clean_build_dir')                  );
ok( ref $cpandep->can('color')                            );
ok( ref $cpandep->can('debug')                            );
ok( ref $cpandep->can('verbose')                          );
ok( ref $cpandep->can('prefer_bin')                       );

