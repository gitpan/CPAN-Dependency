package CPAN::Dependency;
use strict;
use Carp;
use CPANPLUS::Backend;
use File::Spec;
use File::Slurp;
use Module::Depends;
require Exporter;

use constant ALL_CPAN => 'all CPAN modules';

{ no strict;
  $VERSION = '0.02';
  @ISA = qw(Exporter);
  @EXPORT = qw(ALL_CPAN);
}

my($RESET,$BOLD,$RED,$GREEN,$YELLOW);

=head1 NAME

CPAN::Dependency - Analyzes CPAN modules and generates their dependency tree

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use CPAN::Dependency;

    my $cpandeps = CPAN::Dependency->new(process => ALL_CPAN);
    $cpandeps->run;  # this may take some time..

    my %score = $cpandep->score_by_dists;
    my @dists = sort { $score{$b} <=> $score{$a} } keys %score;
    print "Top 10 modules\n";
    for my $dist (@dists[0..9]) {
        printf "%5d %s\n", $score{$dist}, $dist;
    }

=head1 DESCRIPTION

This module can process a set of distributions, up to the whole CPAN, 
and extract the dependency relations between these distributions. 
It also calculates a score for each distribution based on the number 
of times it appears in the prerequisites of other distributions. 
The algorithm is descibed in more details in L<"SCORE CALCULATION">. 

=head1 METHODS

=over 4

=item new()

Creates and returns a new object. 

B<Options>

=over 4

=item *

C<process> - adds modules or distributions to the list of packages to process.

=item *

C<skip> - adds modules or distributions you don't want to process.

=item *

C<color> - use colors (when C<verbose> is also set).

=item *

C<debug> - sets debug level.

=item *

C<prefer_bin> - tells CPANPLUS to prefer binaries programs.

=item *

C<verbose> - sets the verbose mode.

=back

B<Examples>

Create a new C<CPAN::Dependency> object with verbose mode enabled 
and adds three "big" modules to the process list:

    my $cpandeps = new CPAN::Dependency verbose => 1, 
            process => [qw(WWW::Mechanize Maypole Template)]

Create a new C<CPAN::Dependency> object with verbose mode enabled 
and adds all the distributions from the CPAN to the process list: 

    my $cpandeps = new CPAN::Dependency verbose =>1, process => ALL_CPAN;

=cut

sub new {
    my $self = {
        backend     => 0,       # CPANPLUS::Backend object
        
        options => {            # options
            color       => 0,   #  - use ANSI colors?
            debug       => 0,   #  - debug level
            prefer_bin  => 0,   #  - prefer binaries?
            verbose     => 0,   #  - verbose?
        }, 
        
        process => [ ],         # modules/distributions to process
        
        prereqs => { },         # distributions dependencies
        
        skip => {               # modules/distributions to skip
            'perl'       => 1, 
            'perl-5.8.6' => 1, 
            'parrot'     => 1, 
            'ponie'      => 1, 
        }, 
    };
    my $class = ref $_[0] || $_[0]; shift;
    bless $self, $class;

    $self->{backend} = new CPANPLUS::Backend;
    croak "fatal: Can't create CPANPLUS::Backend object" 
      unless defined $self->{backend};
    my $cpan = $self->{backend};
    my $conf = $cpan->configure_object;

    $self->verbose(0);
    $self->debug(0);
    $self->color(1);

    $self->{build_dir} = File::Spec->catdir($conf->get_conf('base'), 
      $cpan->_perl_version(perl => $^X), $conf->_get_build('moddir'));
    
    my %args = @_;

    # treat arguments for which an accessor exists
    for my $attr (keys %args) {
        $self->$attr($args{$attr}) and delete $args{$attr} if $self->can($attr);
    }

    # treat remaining arguments
    for my $attr (keys %args) {
        carp "warning: Unknown option '$attr': ignoring"
    }

    return $self
}

#
# generate accessors for all existing attributes
#
{   no strict 'refs';
    for my $attr (qw(verbose)) {
        *{__PACKAGE__.'::'.$attr} = sub {
            my $self = shift;
            my $value = $self->{options}{$attr};
            $self->{options}{$attr} = shift if @_;
            return $value
        }
    }
}


=item process()

Adds given distribution or module names to the list of packages to process. 
The special argument C<ALL_CPAN> can be used to specify that you want to 
process all packages in the CPAN. 

=cut

sub process {
    my $self = shift;
    croak "warning: No argument given to atribute 'process'." and return unless @_;
    if($_[0] eq ALL_CPAN) {
        push @{ $self->{process} }, sort keys %{ $self->{backend}->module_tree }
    } else {
        push @{ $self->{process} }, ref $_[0] ? @{$_[0]} : @_
    }
}


=item skip()

Adds given distribution or module names to the list of packages that you 
I<don't want> to process. 

=cut

sub skip {
    my $self = shift;
    croak "warning: No argument given to atribute 'skip'." and return unless @_;
    my @packages = ref $_[0] ? @{$_[0]} : @_;
    for my $package (@packages) {
        my $dist = $self->{backend}->parse_module(module => $package)->package_name;
        $self->{skip}{$dist} = 1;
    }
}


=item run()

Launches the execution of the C<CPAN::Dependency> object. 

=cut

sub run {
    my $self = shift;
    my $cpan = $self->{backend};

    my @dists = @{ $self->{process} };

    my($archive,$where) = ();

    for my $name (@dists) {
        my $dist = $cpan->parse_module(module => $name);
        my $dist_name = $dist->package_name;
        
        $self->_vprint($name);
        $self->_vprint("  >> ${YELLOW}skip$RESET\n") and
          next if not defined $dist or $self->{skip}{$dist_name}++;
        
        $self->_vprintf(" => $BOLD%s$RESET %s by %s (%s)\n", $dist_name, 
          $dist->package_version, $dist->author->cpanid, $dist->author->author);
        
        $archive = $where = '';
        
        # fetch and extract the module
        eval {
            $archive = $dist->fetch(force => 1) or next;
            $where   = $dist->extract(force => 1) or next;
        };
        $self->_vprint("  >> $BOLD${RED}CPANPLUS error: $@$RESET\n") and next if $@;

        # read its dependencies
        my $deps = undef;
        eval {
            $deps = Module::Depends->new->dist_dir($where)->find_modules || {};
            $deps = $deps->{requires} || {};
        };
        
        # if it didn't work, try with parsing method
        if($@) {
            $self->_vprint("  >> $BOLD${YELLOW}no META.yml; using parsing method$RESET\n");

            # distribution uses Makefile.PL
            if(-f File::Spec->catfile($where, 'Makefile.PL')) {
                my $builder = read_file( File::Spec->catfile($where, 'Makefile.PL') );
                my($requires) = $builder =~ /PREREQ_PM.*?=>.*?\{(.*?)\}/s;
                eval "{ no strict; \$deps = { $requires \n} }";

            # distribution uses Build.PL
            } elsif(-f File::Spec->catfile($where, 'Build.PL')) {
                my $builder = read_file( File::Spec->catfile($where, 'Build.PL') );
                my($requires) = $builder =~ /requires.*?=>.*?\{(.*?)\}/s;
                eval "{ no strict; \$deps = { $requires \n} }";
            
            } else {
                $self->_vprint("  >> $BOLD${RED}error: no Makefile.PL or Build.PL found$RESET\n");
                next
            }
        }

        $deps ||= {};
        my %deps = ();
        
        print "  \e[1;32mprereqs: ", join(', ', sort keys %$deps), "\e[0m\n";
        
        # $deps contains module names, but we really want distribution names
        # %deps will have the following structure: 
        # 
        #     %deps = (
        #         DIST_NAME => {
        #             PREREQ_DIST_1 => COUNT, 
        #             PREREQ_DIST_2 => COUNT, 
        #             ...
        #         }
        #     )
        # 
        # where COUNT is 0 when PREREQ_DIST_x and DIST_NAME have the same 
        # author, 1 otherwise. 
        # 
        for my $reqmod (keys %$deps) {
            my $reqdist = eval { $cpan->parse_module(module => $reqmod) };
            $self->_vprint("  >> $BOLD${RED}error: no dist found for $reqmod$RESET\n") 
              and next unless defined $reqdist;
            
            $self->_vprint("  >> $BOLD${YELLOW}$reqmod is in Perl core$RESET\n") 
              and next if $reqdist->package_is_perl_core;
            
            $deps{$reqdist->package_name} = $reqdist->author->cpanid ne $dist->author->cpanid ? 1 : 0;
        }
        
        $self->{prereqs}{$dist_name} = {
            prereqs => { %deps }, 
            score => 0, 
            cpanid => $dist->author->cpanid, 
            author => $dist->author->author, 
        };
        
    } continue {
        # clean up
        eval {
           $cpan->_rmdir(dir => $where) if -d $where;
           $cpan->_rmdir(dir => $self->{build_dir});
           $cpan->_mkdir(dir => $self->{build_dir});
        }
    }

    $self->_vprint("${BOLD}END PROCESSING$RESET\n");
    
    # now walk throught the prereqs tree
    for my $dist (keys %{$self->{prereqs}}) {
        $self->_tree_walk($dist, 1);
    }
}


=item deps_by_dists()

Return the hashref of the object that contains the dependency tree indexed 
by distribution names. 

=cut

sub deps_by_dists {
    return $_[0]->{prereqs}
}


=item score_by_dists()

Returns a new hash that contains the score of the processed distributions, 
indexed by the distribution names. 

=cut

sub score_by_dists {
    my $self = shift;
    return map { $_ => $self->{prereqs}{$_}{score} } keys %{$self->{prereqs}};
}

=back


=head2 Internal Methods

=over 4

=item _tree_walk()

Walks throught the dependency tree and updates the score of each distribution. 

=cut

sub _tree_walk {
    my $self = shift;
    my $dist = shift;
    my $depth = shift;
    my $meta = $self->{prereqs}{$dist};

    for my $reqdist (keys %{ $meta->{prereqs} }) {
        # are $dist and $reqdist from the same author?
        my $same_author = $meta->{prereqs}{$reqdist} ;
        
        # increase the score of the dist this one depends upon
        $self->{prereqs}{$reqdist}{score} += $depth * $same_author
        ;#  if exists $self->{prereqs}{$reqdist};
        
        $self->_tree_walk($reqdist, $depth + $same_author);
    }
}

=item _vprint()

Like C<print()> but prints only when option C<verbose> is set. 

=cut

sub _vprint {
    my $self = shift;
    print @_ if $self->{options}{verbose};
    return 1
}

=item _vprintf()

Like C<printf()> but prints only when option C<verbose> is set. 

=cut

sub _vprintf {
    my $self = shift;
    printf @_ if $self->{options}{verbose};
    return 1
}

=back


=head1 OPTIONS

=over 4

=item color()

Selects whether to use ANSI colors or not when verbose is enabled. 
Defaults to yes (1). 

=cut

sub color {
    my $self = shift;
    my $old = $self->{option}{color};
    if(defined $_[0]) {
        $self->{option}{color} = $_[0];
        ($RESET , $BOLD  , $RED    , $GREEN  , $YELLOW) = 
          $self->{option}{color} ? 
            ("\e[0m", "\e[1m", "\e[31m", "\e[32m", "\e[33m") : 
            ('')x5
    }
    return $old
}

=item debug()

Set debug level. Defaults to 0. 

=cut

sub debug {
    my $self = shift;
    my $old = $self->{option}{debug};
    if(defined $_[0]) {
        $self->{option}{debug} = $_[0];
        $self->{backend}->configure_object->set_conf(verbose => $_[0]);
    }
    return $old
}

=item prefer_bin()

Tells CPANPLUS to use binary programs instead of Perl modules when 
there is the choice (i.e. use B<tar(1)> instead of C<Archive::Tar>). 

=cut

sub prefer_bin {
    my $self = shift;
    my $old = $self->{option}{prefer_bin};
    if(defined $_[0]) {
        $self->{option}{prefer_bin} = $_[0];
        $self->{backend}->configure_object->set_conf(perfer_bin => $_[0]);
    }
    return $old
}

=item verbose()

Sets verbose mode to on (1) or off (0). Defaults to off. 

=back


=head1 SCORE CALCULATION

Once the prerequisites for each distribution have been found, the score 
of each distribution is calculated using the following algorithm: 

=over 4

=item 1

for each distribution I<D>

=item 2

S<    >for each prerequisite I<P> of this distribution

=item 3

S<        >if both I<D> and I<P> are not made by the same auhor, 
update the score of I<P> by adding it the current dependency depth

=item 4

S<        >recurse step 1 using I<P>

=back

The aim of this algorithm is to increase the score of distributions 
that are depended upon by many other distributions, while avoiding the 
cases where one author releases a horde of modules which depend upon 
each others. 


=head1 SPEED TIPS

Here are a few tips to speed up the processing when you want to process 
many modules (or the whole CPAN). 

=head2 Local mirror

If it's not the case yet, you should use C<CPAN::Mini> to create your own 
mini-CPAN local mirror. Then you just need to configure C<CPANPLUS> to 
use your mini-CPAN instead of a network mirror. A mini-CPAN can also be 
shared using a web server but if you want speed, you should keep one on 
your local filesystem.

Note that you can also add your own private distributions into your 
mini-CPAN using C<CPAN::Mini::Inject>. This is useful if you want to 
use C<CPAN::Dependency> on modules that are not publicly shared on 
the CPAN. 

More information at L<http://search.cpan.org/dist/CPAN-Mini/> and 
L<http://search.cpan.org/dist/CPAN-Mini-Inject/>.

=head2 Ramdisk

If your system supports this feature (most modern systems do), you should 
create a ramdisk and move the C<CPANPLUS> build directory onto the ramdisk. 
Here are the instructions for Linux. Other systems are left as an exercice 
for the reader C<:-)>

=head3 Ramdisk for Linux

The following commands must be executed as root. 
cpanplus is assumed to be the user that will executes this module. 

=over 4

=item *

Create a ramdisk of S<24 MB>: 

    dd if=/dev/zero of=/dev/ram0 bs=1M count=24

=item *

Format it and creates and Ext2 filesystem: 

    mke2fs -L ramdisk0 /dev/ram0

=item *

Now mount it: 

    mkdir /mnt/ramdisk
    mount /dev/ram0 /mnt/ramdisk/
    mkdir /mnt/ramdisk/cpanplus
    chown cpanplus /mnt/ramdisk/cpanplus/

=item *

Now, as the user cpanplus, move the build directory onto the ramdisk 
and symlink it: 

    mv .cpanplus/5.8.5 /mnt/ramdisk/maddingue/
    ln -s /mnt/ramdisk/maddingue/5.8.5 .cpanplus/5.8.5

=back

Note that we are explicitly avoiding to move the whole F<.cpanplus/> 
directory because it will grow really big during the processing: 
some C<CPANPLUS> cache files are already big, and the sub-directory 
F<author/> will contain a copy of each processed archive. When processing 
the whole CPAN, it means that you'll have here a complete copy of your 
mini-CPAN, so be sure that you have enought disk space (or symlink 
this directory as well to another volume when you have enought space). 

=head3 Ramdisk for Mac OS X

Here is a small shell script that creates, format and mount a ramdisk 
of S<32 MB>. Its size can be changed by changing the number of blocks, 
where one block is S<512 bytes>. 

    #!/bin/sh
    BLOCK=64000
    dev=`hdid -nomount ram://$BLOCKS`
    newfs_hfs -v RAMDisk $dev
    mkdir /Volumes/RAMDisk
    chmod 777 /Volumes/RAMDisk
    mount -t hfs $dev /Volumes/RAMDisk

Then follow the same instructions for moving the F<build/> directory 
as given for Linux. 


=head1 DIAGNOSTICS

=over 4

=item Can't create CPANPLUS::Backend object

B<(F)> C<CPANPLUS::Backend> was unable to create and return a new object. 

=item No argument given to atribute '%s'

B<(W)> As the message implies, you didn't supply the expected argument 
to the attribute. 

=item Unknown option '%s': ignoring

B<(W)> You gave to C<new()> an unknown attribute name.

=back


=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni, E<lt>sebastien@aperghis.netE<gt>

=head1 BUGS

Please report any bugs or feature requests to
L<bug-cpan-dependency@rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPAN-Dependency>. 
I will be notified, and then you'll automatically be notified 
of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 SE<eacute>bastien Aperghis-Tramoni, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of CPAN::Dependency
