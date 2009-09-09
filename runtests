#!/usr/bin/perl

use lib 'lib';
use XML::TreePP::XMLPath;

#require ( 't/XML-TreePP-XMLPath.t' );

opendir (TD, 't');
while (my $testfile = readdir(TD)) {
    next unless $testfile =~ /\.t$/;
    print "[ ".$testfile." ]\n";
    require ( ("t/".$testfile) );
}
