use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'XML::TreePP::XMLPath',
    VERSION_FROM      => 'lib/XML/TreePP/XMLPath.pm', # finds $VERSION
    PREREQ_PM         => { XML::TreePP => 0.33 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/XML/TreePP/XMLPath.pm', # retrieve abstract from module
       AUTHOR         => 'Russell E Glaue <rglaue@localdomain>') : ()),
);
