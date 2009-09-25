# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl XML-TreePP-XMLPath.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 8;
BEGIN { use_ok('XML::TreePP::XMLPath'); };
use_ok('XML::TreePP'); 
use_ok('Data::Dump');

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $tpp = XML::TreePP->new();
my $tppx = XML::TreePP::XMLPath->new();

ok ( defined($tppx) && ref $tppx eq 'XML::TreePP::XMLPath', 'new()' );

my $xmldoc =<<XML_EOF;
<test>
  <node id="one">
    <data>test data one</data>
  </node>
  <node id="two">
    <data>test data two</data>
  </node>
  <node id="three">
    <data>
        <test>1</test>
        <![CDATA[<html><body>test data three</body></html>]]>
    </data>
  </node>
</test>
XML_EOF

my $tree = $tpp->parse($xmldoc);
my ($path, $result, $flag);


# Test XML Document Parsing and filtering by XMLPath
# ok ( $tree->{'test'}->{'node'}->[2]->{'data'}->{'#text'} eq '<html><body>test data three</body></html>', "XML Tree Parsing );
$result = $tppx->filterXMLDoc($tree, '/test/node[3]/data');
ok ( $result->[0]->{'#text'} eq $tree->{'test'}->{'node'}->[2]->{'data'}->{'#text'}, "filterXMLDoc() by XML node" ) || diag explain $result;


# Test getting elements and attributes
$path   = '/test/node';
# elements
$result = $tppx->getElements($tree,$path);
$flag   = 0;
if (   ( $result->[0]->{'data'} eq 'test data one' )
    && ( $result->[1]->{'data'} eq 'test data two' )
    && ( $result->[2]->{'data'}->{'#text'} eq '<html><body>test data three</body></html>' )
    && ( $result->[2]->{'data'}->{'test'} == 1 ) )
    {
        $flag = 1;
    }
ok ( $flag == 1, "getElements() by XML node" );
# attributes
$result = $tppx->getAttributes($tree,$path);
$flag   = 0;
if (   ( $result->[0]->{'id'} eq 'one' )
    && ( $result->[1]->{'id'} eq 'two' )
    && ( $result->[2]->{'id'} eq 'three' ) )
    {
        $flag = 1;
    }
ok ( $flag == 1, "getAttributes() by XML node" );


# Test getting values
$path   = '/test/node/@id';
#$path   = '/test/node/@id';
$result = $tppx->getValues($tree,$path);
$flag   = 0;
if (   ( $result->[0] eq 'one' )
    && ( $result->[1] eq 'two' )
    && ( $result->[2] eq 'three' )
    && ( @{$result} == 3 ) )
    {
        $flag = 1;
    }
ok ( $flag == 1, "getValues() by XML attribute" ) || explain $result;



