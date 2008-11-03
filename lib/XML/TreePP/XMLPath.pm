=pod

=head1 NAME

XML::TreePP::XMLPath - Something similar to XPath, allowing definition of paths to XML subtrees

=head1 SYNOPSIS

    use XML::TreePP;
    use XML::TreePP::XMLPath;
    
    my $tpp = XML::TreePP->new();
    my $tppx = XML::TreePP::XMLPath->new();
    
    my $tree = { rss => { channel => { item => [ {
        title   => "The Perl Directory",
        link    => "http://www.perl.org/",
    }, {
        title   => "The Comprehensive Perl Archive Network",
        link    => "http://cpan.perl.org/",
    } ] } } };
    my $xml = $tpp->write( $tree );

Get a subtree of the XMLTree:

    my $xmlsub = $tppx->getSubTree( $xml , q{rss/channel/item[title="The Comprehensive Perl Archive Network"]} );
    print $xmlsub->{'link'};

Iterate through all attributes and Elements of each <item> XML element:

    my $xmlsub = $tppx->getSubTree( $xml , q{rss/channel/item} );
    my $h_attr = $tppx->getAttributes( $xmlsub );
    my $h_elem = $tppx->getElements( $xmlsub );
    foreach $attrHash ( @{ $h_attr } ) {
        while my ( $attrKey, $attrVal ) = each ( %{$attrHash} ) {
            ...
        }
    }
    foreach $elemHash ( @{ $h_elem } ) {
        while my ( $elemName, $elemVal ) = each ( %{$elemHash} ) {
            ...
        }
    }

=head1 DESCRIPTION

A Pure PERL extension to Pure PERL XML::TreePP module to support paths to XML
subtree content. This may seem similar to XPath, but it is not XPath.

=head1 REQUIREMENTS

The following perl modules are depended on by this module:

=over 4

=item *     XML::TreePP

=item *     Params::Validate

=back

=head1 IMPORTABLE METHODS

When the calling application invokes this module in a use clause, the following
methods can be imported into its space.

=over 4

=item *     getAttributes

=item *     getElements

=item *     getSubtree

=item *     parseXMLPath

=back

Example:

    use XML::TreePP::XMLPath qw(getAttributes getElements getSubtree parseXMLPath);

=head1 XMLPath PHILOSOPHY

Referring to the following XML Data.

    <paragraph>
        <sentence language="english">
            <words>Do red cats eat yellow food</words>
            <punctuation>?</punctuation>
        </sentence>
        <sentence language="english">
            <words>Brown cows eat green grass</words>
            <punctuation>.</punctuation>
        </sentence>
    </paragraph>

Where the path "C<parapgraph/sentence[@language=english]/words>" matches
"C<Do red cats eat yellow food>"

And the path "C<parapgraph/sentence[punctuation=.]/words>" matches 
"C<Brown cows eat green grass>"

So that "C<@attr=val>" is identified as an attribute inside the
"<tag attr=val></tag>"

And "C<attr=val>" is identified as a nested attribute inside the
"<tag><attr>val</attr></tag>"

After XML::TreePP parses the above XML, it looks like this:

    {
      paragraph => {
            sentence => [
                  {
                    "-language" => "english",
                    punctuation => "?",
                    words => "Do red cats eat yellow food",
                  },
                  {
                    "-language" => "english",
                    punctuation => ".",
                    words => "Brown cows eat green grass",
                  },
                ],
          },
    }

B<Things To Note>

Note that attributes are specified in the XMLPath as C<@attribute_name>, but
after XML::TreePP parses the XML Document, the attribute name is identifed as
C<-attribute_name> in the resulting parsed document.

XMLPath requires attributes to be specified as C<@attribute_name> and takes care
of the conversion from C<@> to C<-> behind the scenes when accessing the
XML::TreePP parsed XML document.

Child elements on the next level of a parent element are accessible as attributes
as C<attribute_name>. This is the same format as C<@attribute_name> except
without the C<@> symbol. Specifying the attribute without an C<@> symbol
identifies the attribute as a child element of the parent element being
evaluated.

Child element values are only accessible as C<CDATA>. That is when the
element being evaluated is C<animal>, the attribute (or child element) is
C<cat>, and the value of the attribue is C<tiger>, it is presented as this:

    <jungle>
        <animal>
            <cat>tiger</cat>
        </animal>
    </jungle>

The XMLPath used to access the key=value pair of C<cat=tiger> for element
animal would be as follows:

    jungle/animal[cat=tiger]

However, note that in this case, due to how XML::TreePP parses the XML document,
the above XMLPath is invalid:

    <jungle>
        <animal>
            <cat color="black">tiger</cat>
        </animal>
    </jungle>

However, in this case, the following two XMLPaths would be valid:

    jungle/animal/cat[#text=tiger]
    jungle/animal/cat[@color="black"][#text=tiger]

One should realize that in the second case, the element C<cat> is being
evaluated, and not the element C<animal> as in the first case. And will be
undesireable if you want to evaluate C<animal>.

As such, this is a current limitation to XMLPath. This limitation would be
resolved by XPath Query methods. However XMLPath is not XPath.

=head1 METHODS

=cut

package XML::TreePP::XMLPath;

use 5.008008;
use strict;
use warnings;
use Exporter;
use Params::Validate qw(:all);
use Pod::Usage;
use XML::TreePP;

BEGIN {
    use vars      qw(@ISA @EXPORT @EXPORT_OK);
    @ISA        = qw(Exporter);
    @EXPORT     = qw();
    @EXPORT_OK  = qw(&charlexsplit &getAttributes &getElements &getSubtree &parseXMLPath);

    use vars      qw($REF_NAME);
    $REF_NAME   = "XML::TreePP::XMLPath";  # package name

    use vars      qw( $VERSION );
    $VERSION    = '0.50';
}

=pod

=head2 new

Create a new object instances of this module.

=over 4

=item * I<returns>

An object instance of this module.

=back

    $tppx = new XML::TreePP::XMLPath();

=cut

# new
#
# It is not necessary to create an object of this module.
# However, if you choose to do so any way, here is how you do it.
#
#    my $obj = new XML::TreePP::XMLPath;
#
# This module supports being called by two methods.
# 1. By importing the functions you wish to use, as in:
#       use XML::TreePP::XMLPath qw( function1 function2 );
#       function1( args )
# 2. Or by calling the functions in an object oriented mannor, as in:
#       my $tppx = new XML::TreePP::XMLPath()
#       $tppx->function1( args )
# Using either method works the same and returns the same output.
#
sub new {
    my $pkg	= shift;
    my $class	= ref($pkg) || $pkg;
    my $self	= bless {}, $class;
    return $self;
}


=pod

=head2 charlexsplit

An analysis method for single character boundry and start/stop tokens

=over 4

=item * C<string>

The string to analyse

=item * C<boundry_start>

The single character starting boundry separating wanted elements

=item * C<boundry_stop>

The single character stopping boundry separating wanted elements

=item * C<tokens>

A { start_char => stop_char } hash reference of start/stop tokens.
The characters in C<string> contained within a start_char and stop_char are not
evaluated to match boundires.

=item * C<boundry_begin>

Provide "1" if the beginning of the string should be treated as a 
C<boundry_start> character.

=item * C<boundry_end>

Provide "1" if the ending of the string should be treated as a C<boundry_stop>
character.

=item * I<returns>

An arrary reference of elements

=back

    $elements = charlexsplit (
                        string         => $string,
                        boundry_start  => $charA,   boundry_stop   => $charB,
                        tokens         => \@tokens,
                        boundry_begin  => $char1,   boundry_end    => $char2 );

=cut

# charlexsplit
# @brief    A lexical analysis function for single character boundry and start/stop tokens
# @param    string          the string to analyse
# @param    boundry_start   the single character starting boundry separating wanted elements
# @param    boundry_stop    the single character stopping boundry separating wanted elements
# @param    tokens          a { start_char => stop_char } hash reference of start/stop tokens
# @param    boundry_begin   set to "1" if the beginning of the string should be treated as a 'boundry_start' character
# @param    boundry_end     set to "1" if the ending of the string should be treated as a 'boundry_stop' character
# @return   an arrary reference of the resulting parsed elements
#
# Example:
# {
# my @el = charlexsplit   (
#   string        => q{abcdefg/xyz/path[@key='val'][@key2='val2']/last},
#   boundry_start => '/',
#   boundry_stop  => '/',
#   tokens        => [qw( [ ] ' ' " " )],
#   boundry_begin => 1,
#   boundry_end   => 1
#   );
# print join(', ',@el),"\n";
# my @el2 = charlexsplit (
#   string        => $el[2],
#   boundry_start => '[',
#   boundry_stop  => ']',
#   tokens        => [qw( ' ' " " )],
#   boundry_begin => 0,
#   boundry_end   => 0
#   );
# print join(', ',@el2),"\n";
# my @el3 = charlexsplit (
#   string        => $el2[0],
#   boundry_start => '=',
#   boundry_stop  => '=',
#   tokens        => [qw( ' ' " " )],
#   boundry_begin => 1,
#   boundry_end   => 1
#   );
# print join(', ',@el3),"\n";
#
# OUTPUT:
# abcdefg, xyz, path[@key='val'][@key2='val2'], last
# @key='val', @key2='val2'
# @key, 'val'
#
sub charlexsplit (@) {
    my $self            = shift if ref($_[0]) eq $REF_NAME || undef;
    my %args    =   validate ( @_,  {   string          => { type => SCALAR,   optional => 0 },
                                        boundry_start   => { type => SCALAR,   optional => 0 },
                                        boundry_stop    => { type => SCALAR,   optional => 0 },
                                        tokens          => { type => ARRAYREF, optional => 0 },
                                        boundry_begin   => { type => SCALAR,   optional => 1 },
                                        boundry_end     => { type => SCALAR,   optional => 1 }
                                    }
                             );

    my %args            = @_;
    my $string          = $args{'string'};        # The string to parse
    my $boundry_start   = $args{'boundry_start'}; # The boundry character separating wanted elements
    my $boundry_stop    = $args{'boundry_stop'};  # The boundry character separating wanted elements
    my %tokens          = @{$args{'tokens'}};     # The start=>stop characters that must be paired inside an element
    my $boundry_begin   = $args{'boundry_begin'} || 0;
    my $boundry_end     = $args{'boundry_end'} || 0;


    # split the string into individual characters
    my @string  = split(//,$string);

    # initialize variables
    my $next = undef;
    my $current_element = undef;
    my @elements;
    my $collect = 0;

    if ($boundry_begin == 1) {
        $collect = 1;
    }
    CHAR: foreach my $c (@string) {
        if (!defined $next) {       # If not looking for the 'stop' matching token
            if ($c eq $boundry_stop) {                  # If this character matches the boundry_stop character...
                if (defined $current_element) {         # -and the current_element is defined...
                    push(@elements,$current_element);   # -put the current element in the elements array...
                    $current_element = undef;           # -stop collecting elements.
                }
                if ($boundry_start ne $boundry_stop) {  # -and the start and stop boundries are different
                    $collect = 0;                       # -turn off collection
                } else {
                    $collect = 1;                       # -but keep collection on if the boundries are the same
                }
                next CHAR;              # Process the next character if this character matches the boundry_stop character.
            }
            if ($c eq $boundry_start) {                 # If this character matches the boundry_start character...
                $collect = 1;                           # -turn on collection
                next CHAR;              # Process the next character if this character matches the boundry_start character.
            }
        }   # continue if the current character does not match stop|start boundry, or if we are looking for the 'stop' matching token (do not turn off collection)
        TKEY: foreach my $tkey (keys %tokens) {
            if (! defined $next) {  # If not looking for the 'stop' matching token
                if ($c eq $tkey) {          # If this character matches the 'start' matching token...
                    $next = $tokens{$tkey}; # -start looking for the 'stop' matching token
                    last TKEY;
                }
            } elsif
               (defined $next) {                # If I am looking for the 'stop' matching token
                if ($c eq $next) {          # If this character matches the 'stop' matching token...
                    $next = undef;          # -then I am no longer looking for the 'stop' matching token.
                    last TKEY;
                }
            }
        }
        if ($collect == 1) {
            $current_element .= $c;
        }
    }
    if ($boundry_end == 1) {
        if (defined $current_element) {
            push(@elements,$current_element);
            $current_element = undef;
        }
    }

    return \@elements if @elements >= 1;
    return undef;
}

=pod

=head2 parseXMLPath

Parse a string that represents the path to a XML element in a XML document
The XML Path is something like XPath, but it is not

=over 4

=item * C<XMLPath>

The XML path to be parsed.

=item * I<returns>

An arrary reference of hash reference elements of the XMLPath.
Note that the XML attributes, known as "@attr" are transformed into "-attr".
The preceeding "-" minus in place of the "@" at is the recognized format of
attributes in the XML::TreePP module.

Being that this is intended to be a submodule of XML::TreePP, the format of 
'@attr' is converted to '-attr' to conform with how XML::TreePP handles
attributes.

See: XML::TreePP->set( attr_prefix => '@' ); for more information.
This module only supports the default format, '-attr', of attributes at this time.

=back

    $parsedXMLPath = parseXMLPath( $XMLPath );

=cut

# parseXMLPath
# something like XPath parsing, but it is not
# @param    xmlpath     the XML path to be parsed
# @return   an array reference of hash reference elements of the path
#
# Example:
# use Data::Dumper;
# print Dumper (parseXMLPath(q{abcdefg/xyz/path[@key='val'][key2=val2]/last}));
#
# OUTPUT:
#  $VAR1 = [
#          [ 'abcdefg', undef ],
#          [ 'xyz', undef ],
#          [ 'path', 
#            [
#              [ '-key', 'val' ],
#              [ 'key2', 'val2' ]
#            ]
#          ],
#          [ 'last', undef ]
#        ];
#
# Philosophy:
# <paragraph>
#     <sentence language="english">
#         <words>Do red cats eat yellow food</words>
#         <punctuation>?</punctuation>
#     </sentence>
#     <sentence language="english">
#         <words>Brown cows eat green grass</words>
#         <punctuation>.</punctuation>
#     </sentence>
# <paragraph>
# Where the path 'parapgraph/sentence[@language=english]/words' matches 'Do red cats eat yellow food'
# And the path 'parapgraph/sentence[punctuation=.]/words' matches 'Brown cows eat green grass'
# So that '@attr=val' is identified as an attribute inside the <tag attr=val></tag>
# And 'attr=val' is identified as a nested attribute inside the <tag><attr>val</attr></tag>
#
# Note the format of '@attr' is converted to '-attr' to conform with how XML::TreePP handles this
#
sub parseXMLPath ($) {
    my $self        = shift if ref($_[0]) eq $REF_NAME || undef;
    validate_pos( @_, 1);
    my $path        = shift;
    my $hpath       = [];

    my $h_el = charlexsplit   (
        string        => $path,
        boundry_start => '/',
        boundry_stop  => '/',
        tokens        => [qw( [ ] ' ' " " )],
        boundry_begin => 1,
        boundry_end   => 1
        );
    foreach my $el (@{$h_el}) {
        my $h_param = charlexsplit (
            string        => $el,
            boundry_start => '[',
            boundry_stop  => ']',
            tokens        => [qw( ' ' " " )],
            boundry_begin => 0,
            boundry_end   => 0
        ) || undef;
        if (defined $h_param) {
            my ($el2) = $el =~ /^([^\[]*)/;
            my $ha_param = [];
            foreach my $param (@{$h_param}) {
                my ($attr,$val) = $param =~ /([^\=]*)\=[\'\"]?(.*[^\'\"])[\'\"]?/;
                if ((! defined $attr) && (! defined $val)) {
                    ($attr) = $param =~ /([^\=]*)\=[\'\"]?[\'\"]?/;
                    $val = '';
                }
                if ((! defined $attr) && (! defined $val)) {
                    ($attr) = $param =~ /^([^\=]*)$/;
                    $val = undef;
                }
                $attr =~ s/^\@/\-/;  # See: XML::TreePP->set( attr_prefix => '@' );, where default is '-'
                push (@{$ha_param},[$attr, $val]);
            }
            push (@{$hpath},[$el2, $ha_param]);
        } else {
            push (@{$hpath},[$el, undef]);
        }

    }
    return $hpath;
}

=pod

=head2 validateAttrValue

Validate a subtree of a parsed XML document to have a paramter set in which
attribute matches value.

=over 4

=item * C<XMLSubTree>

The XML tree, or subtree, (element) to validate.
This is an XML document parsed by the XML::TreePP->parse() method.

The XMLSubTree can be an ARRAY of multiple elements to evaluate.
The XMLSubTree would be validated as follows:

    $subtree[item]->{'attribute'} eq "value"
    $subtree[item]->{'attribute'}->{'value'} exists
    returning: $subtree[item] if valid (returns the first valid [item])

Or the XMLSubTree can be a HASH which would be a single element to evaluate.
The XMLSubTree would be validated as follows:

    $subtree{'attribute'} eq "value"
    $subtree{'attribute'}->{'value'} exists
    returning: $subtree if valid

=item * C<params>

Validate the element having an attribute matching value in this current
XMLSubTree position

This is an array reference of C<[["attr1","val"],["attr2","val"]]>, as in:

    my $params = [[ "MyKeyName" , "Value_to_match_for_KeyName" ]];

=item * I<returns>

The subtree that is validated, or undef if not validated

=back

    $validatedXMLTree = validateAttrValue( $XMLTree , \@params );

=cut

# validateAttrValue
# @param    xmlsubtree  the XML sub tree (element) to validate
# @param    [params]    validate the element having this [attribute=value] in this current sub tree position
# @return   the subtree that is validated, or undef if not validated
#
# subtree can be an ARRAY of multiple elements to evaluate, or a HASH which
# would be a single element to evaluate, and the subtree can be validated
# as follows:
# $subtree[item]->{'attribute'} eq "value"
# $subtree[item]->{'attribute'}->{'value'} exists
# returning: $subtree[item] if valid (returns the first valid [item])
# $subtree{'attribute'} eq "value"
# $subtree{'attribute'}->{'value'} exists
# returning: $subtree if valid
#
# In the first case with an ARRAY Reference, the first item in the array
# that can be validated is what is returned. If you want all items in the
# array that are valid, you will need to pass each item in to this function
# individualy for validating.
#
sub validateAttrValue ($$) {
    my $self        = shift if ref($_[0]) eq $REF_NAME || undef;
    validate_pos( @_, 1, 1);
    my $subtree     = shift;
    my $params      = shift;
    if (ref $subtree eq "ARRAY") {
        foreach my $sub (@{$subtree}) {
            my $subtree_tmp = validateAttrValue($sub,$params);
            return $subtree_tmp if defined $subtree_tmp;
        }
        return undef;
    } elsif (ref $subtree eq "HASH") {
        my $param_match_flag = 0;
        PARAM: foreach my $param (@{$params}) {
            #my $attribute   = shift @{$param};
            #my $value       = shift @{$param};
            my $attribute   = $param->[0];
            my $value       = $param->[1];
            if (! exists $subtree->{$attribute}) {
                $param_match_flag = 0;
                last PARAM;
            }
            if      (   (ref    $subtree->{$attribute} eq "SCALAR" )
                     && (defined                $value             )
                     && (    ${$subtree->{$attribute}} eq $value   ) ) {
                $param_match_flag = 1;
                next PARAM;
            } elsif (   (ref    $subtree->{$attribute} eq "SCALAR" )
                     && (! defined              $value             )
                     && (! defined ${$subtree->{$attribute}}       ) ) {
                $param_match_flag = 1;
                next PARAM;
            } elsif (   (ref    $subtree->{$attribute} eq "SCALAR" )
                     && (                       $value eq ''       )
                     && (    ${$subtree->{$attribute}} eq ''       ) ) {
                $param_match_flag = 1;
                next PARAM;
            } elsif (   (ref    $subtree->{$attribute} eq "HASH"   )
                     && (defined                $value             )
                     && (exists $subtree->{$attribute}->{$value}   ) ) {
                $param_match_flag = 1;
                next PARAM;
            } elsif (    ref    $subtree->{$attribute} eq "ARRAY"  )   {
                foreach my $attr_val (@{$subtree->{$attribute}}) {
                    if      (   (! defined    $value          )
                             && (! defined $attr_val          )) {
                        $param_match_flag = 1;
                        next PARAM;
                    } elsif (   (  defined    $value          )
                             && (             $value eq ''    )
                             && (  defined $attr_val          )
                             && (          $attr_val eq ''    )) {
                        $param_match_flag = 1;
                        next PARAM;
                    } elsif (   (  defined    $value          )
                             && (  defined $attr_val          )
                             && (          $attr_val eq $value)) {
                        $param_match_flag = 1;
                        next PARAM;
                    }
                }
                $param_match_flag = 0;
                last PARAM;
            } else {
                if      (   (! defined $value                      )
                         && (! defined $subtree->{$attribute}      )) {
                    $param_match_flag = 1;
                } elsif (   (  defined                 $value      )
                         && (                          $value eq '')
                         && (  defined $subtree->{$attribute}      )
                         && (          $subtree->{$attribute} eq '')) {
                    $param_match_flag = 1;
                } elsif ($subtree->{$attribute} eq $value) {
                    $param_match_flag = 1;
                } else {
                    $param_match_flag = 0;
                    last PARAM;
                }
                next PARAM;
            }
        }
        if ($param_match_flag == 1) {
            return $subtree;
        } else {
            return undef;
        }
    }
    return undef;
}

=pod

=head2 getSubtree

Return a subtree of an XML tree from a given XMLPath.
See parseXMLPath() for the format of a XMLPath.

=over 4

=item * C<XMLTree>

An XML::TreePP parsed XML document.

=item * C<XMLPath>

The path within the XML Tree to retrieve. See parseXMLPath()

=item * I<returns>

A subtree of a XML::TreePP parsed XMLTree found at the XMLPath.

=back

    $XMLSubTree = getSubtree ( $XMLTree , $XMLPath ) 

=cut

# getSubtree
# @brief  return a subtree of an XML tree from a given path (see parseXMLPath)
# @param    xmltree     the XML tree
# @param    xmlpath     the path within the XML Tree to retrieve (see parseXMLPath)
# @return   a subtree of the XMLTree from the given XMLPath
sub getSubtree ($$) {
    my $self        = shift if ref($_[0]) eq $REF_NAME || undef;
    validate_pos( @_, 1, 1);
    my $tree        = shift;
    my $path        = shift;

    my $hpath       = parseXMLPath($path);
    my $subtree     = $tree;


    sub _findsubtree($$) {
        my $subtree     = shift;
        my $xmlpath     = shift;
        if (! @{$xmlpath} >= 1) {
            return $subtree;
        }
        if (ref $subtree eq "ARRAY") {
            foreach my $sub (@{$subtree}) {
                my $subtree_tmp = _findsubtree($sub,$xmlpath);
                return $subtree_tmp if defined $subtree_tmp;
            }
            return undef;
        } elsif (ref $subtree eq "HASH") {
            my $path_element = shift @{$xmlpath};
            my $element      = shift @{$path_element};
            my $params       = shift @{$path_element};
            if ((! defined $element) && (! defined $params)) {
                return _findsubtree($subtree,$xmlpath)
            } elsif ((defined $element) && (! defined $params)) {
                if (exists $subtree->{$element}) {
                    return _findsubtree($subtree->{$element},$xmlpath);
                } else {
                    return undef;
                }
            } else {
                my $validated_subtree;
                if ((! defined $element) || ($element eq '')) {
                    $validated_subtree = validateAttrValue($subtree,$params);
                } else {
                    $validated_subtree = validateAttrValue($subtree->{$element},$params);
                }
                if (! defined $validated_subtree) {
                    return undef;
                } else {
                    return _findsubtree($validated_subtree,$xmlpath);
                }
            }
        } else {
            # Terminal state with more xmlpath elements yet to be evaluated
            return undef;
        }
    }

    return _findsubtree($subtree,$hpath);
}

=pod

=head2 getAttributes

=over 4

=item * C<XMLTree>

An XML::TreePP parsed XML document.

=item * C<XMLPath>

The path within the XML Tree to retrieve. See parseXMLPath()

=item * I<returns>

An array refrence of [{attribute=>value}], or undef if none found

In the case where the XML Path points at a multi-same-name element, the return
value is a ref arrary of ref hashes, one hash ref for each element.

Example Returned Data:

    XML Path points at a single named element
    [ {attr1=>val,attr2=>val} ]

    XML Path points at a multi-same-name element
    [ {attr1A=>val,attr1B=>val}, {attr2A=>val,attr2B=>val} ]

=back

    $attributes = getAttributes ( $XMLTree , $XMLPath );

=cut

# getAttributes
# @param    xmltree     the XML::TreePP parsed xml document
# @parah    xmlpath     the XML path (See parseXMLPath)
# @return   an array ref of [{attr=>val, attr=>val}], or undef if none found
#
# In the case where the XML Path points at a multi-same-name element, the
# return value is a ref arrary of ref arrays, one for each element.
# Example:
#  XML Path points at a single named element
#  [{attr1=>val, attr2=>val}]
#  XML Path points at a multi-same-name element
#  [ {attr1A=>val,attr1B=>val}, {attr2A=>val,attr2B=val} ]
#
sub getAttributes ($$) {
    my $self        = shift if ref($_[0]) eq $REF_NAME || undef;
    validate_pos( @_, 1, 0);
    my $tree        = shift;
    my $path        = shift || undef;
    my $subtree;
    if (defined $path) {
        $subtree = getSubtree($tree,$path);
    } else {
        $subtree = $tree;
    }
    my @attributes;
    if (ref $subtree eq "ARRAY") {
        foreach my $element (@{$subtree}) {
            my $e_attr = getAttributes($element);
            foreach my $a (@{$e_attr}) {
                push(@attributes,$a);
            }
        }
    } elsif (ref $subtree eq "HASH") {
        my $e_elem;
        while (my ($k,$v) = each(%{$subtree})) {
            if ($k =~ /^\-/) {
                $k =~ s/^\-//;
                $e_elem->{$k} = $v;
            }
        }
        push(@attributes,$e_elem);
    } else {
        return undef;
    }
    return \@attributes;
}

=pod

=head2 getElements

Gets the child elements found at a specified XMLPath

=over 4

=item * C<XMLTree>

An XML::TreePP parsed XML document.

=item * C<XMLPath>

The path within the XML Tree to retrieve. See parseXMLPath()

=item * I<returns>

An array refrence of [{element=>value}], or undef if none found

An array reference of a hash reference of elements (not attributes) and each
elements XMLSubTree, or undef if none found. If the XMLPath points at a
multi-valued element, then the subelements of each element at the XMLPath are
returned as separate hash references in the returning array reference.

The format of the returning data is the same as the getAttributes() method.

The XMLSubTree is fetched based on the provided XMLPath. Then all elements
found under that XMLPath are placed into a referenced hash table to be
returned. If an element found has additional XML data under it, it is all
returned just as it was provided.

Simply, this strips all XML attributes found at the XMLPath, returning the
remaining elements found at that path.

If the XMLPath has no elements under it, then undef is returned instead.

=back

    $elements = getElements ( $XMLTree , $XMLPath );

=cut

# getElements
# @param    xmltree     the XML::TreePP parsed xml document
# @parah    xmlpath     the XML path (See parseXMLPath)
# @return   an array ref of [[element,{val}]] where val can be a scalar or a subtree, or undef if none found
#
# See also getAttributes function for further details of the return type
#
sub getElements ($$) {
    my $self        = shift if ref($_[0]) eq $REF_NAME || undef;
    validate_pos( @_, 1, 0);
    my $tree        = shift;
    my $path        = shift || undef;
    my $subtree;
    if (defined $path) {
        $subtree = getSubtree($tree,$path);
    } else {
        $subtree = $tree;
    }
    my @elements;
    if (ref $subtree eq "ARRAY") {
        foreach my $element (@{$subtree}) {
            my $e_elem = getElements($element);
            foreach my $a (@{$e_elem}) {
                push(@elements,$a);
            }
        }
    } elsif (ref $subtree eq "HASH") {
        my $e_elem;
        while (my ($k,$v) = each(%{$subtree})) {
            if ($k !~ /^\-/) {
                $e_elem->{$k} = $v;
            }
        }
        push(@elements,$e_elem);
    } else {
        return undef;
    }
    return \@elements;
}


1;
__END__

=pod

=head1 EXAMPLES

=head2 Method: new

It is not necessary to create an object of this module.
However, if you choose to do so any way, here is how you do it.

    my $obj = new XML::TreePP::XMLPath;

This module supports being called by two methods.

=over 4

=item 1.  By importing the functions you wish to use, as in:

    use XML::TreePP::XMLPath qw( function1 function2 );
    function1( args )

See IMPORTABLE METHODS section for methods available for import

=item 2.  Or by calling the functions in an object oriented mannor, as in:

    my $tppx = new XML::TreePP::XMLPath;
    $tppx->function1( args )

=back

Using either method works the same and returns the same output.

=head2 Method: charlexsplit

Here are three steps that can be used to parse values out of a string:

Step 1:

First, parse the entire string deliminated by the / character.

    my $el = charlexsplit   (
        string        => q{abcdefg/xyz/path[@key='val'][@key2='val2']/last},
        boundry_start => '/',
        boundry_stop  => '/',
        tokens        => [qw( [ ] ' ' " " )],
        boundry_begin => 1,
        boundry_end   => 1
        );
    dump( $el );

Output:

    ["abcdefg", "xyz", "path[\@key='val'][\@key2='val2']", "last"],

Step 2:

Second, parse the elements from step 1 that have key/val pairs, such that
each single key/val is contained by the [ and ] characters

    my $el = charlexsplit (
        string        => q( path[@key='val'][@key2='val2'] ),
        boundry_start => '[',
        boundry_stop  => ']',
        tokens        => [qw( ' ' " " )],
        boundry_begin => 0,
        boundry_end   => 0
        );
    dump( $el );

Output:

    ["\@key='val'", "\@key2='val2'"]

Step 3:

Third, parse the elements from step 2 that is a single key/val, the single
key/val is delimintated by the = character

    my $el = charlexsplit (
        string        => q{ @key='val' },
        boundry_start => '=',
        boundry_stop  => '=',
        tokens        => [qw( ' ' " " )],
        boundry_begin => 1,
        boundry_end   => 1
        );
    dump( $el );

Output:

    ["\@key", "'val'"]

Note that in each example the C<tokens> represent a group of escaped characters
which, when analysed, will be collected as part of an element, but will not be
allowed to match any starting or stopping boundry.

So if you have a start token without a stop token, you will get undesired
results. This example demonstrate this data error.

    my $el = charlexsplit   (
        string        => q{ path[@key='val'][@key2=val2'] },
        boundry_start => '[',
        boundry_stop  => ']',
        tokens        => [qw( ' ' " " )],
        boundry_begin => 0,
        boundry_end   => 0
        );
    dump( $el );

Undesired output:

    ["\@key='val'"]

In this example of bad data being parsed, the C<boundry_stop> character C<]> was
never matched for the C<key2=val2> element.

And there is no error message. The charlexsplit method throws away the second
element silently due to the token start and stop mismatch.

=head2 Method: parseXMLPath

    use XML::TreePP::XMLPath qw(parseXMLPath);
    use Data::Dump qw(dump);
    
    my $parsedPath = parseXMLPath(
                                  q{abcdefg/xyz/path[@key1='val1'][key2='val2']/last}
                                  );
    dump ( $parsedPath );

Output:

    [
      ["abcdefg", undef],
      ["xyz", undef],
      ["path", [["-key1", "val1"], ["key2", "val2"]]],
      ["last", undef],
    ]

=head2 Method: validateAttrValue

    #!/usr/bin/perl
    use XML::TreePP;
    use XML::TreePP::XMLPath qw(getSubtree);
    use Data::Dump qw(dump);
    #
    # The XML document data
    my $xmldata=<<XMLEND;
        <paragraph>
            <sentence language="english">
                <words>Do red cats eat yellow food</words>
                <punctuation>?</punctuation>
            </sentence>
            <sentence language="english">
                <words>Brown cows eat green grass</words>
                <punctuation>.</punctuation>
            </sentence>
        </paragraph>
    XMLEND
    #
    # Parse the XML docuemnt.
    my $tpp = new XML::TreePP;
    my $xmldoc = $tpp->parse($xmldata);
    print "Output Test #1\n";
    dump( $xmldoc );
    #
    # Retrieve the sub tree of the XML document at path "paragraph/sentence"
    my $xmlSubTree = getSubtree($xmldoc, "paragraph/sentence");
    print "Output Test #2\n";
    dump( $xmlSubTree );
    #
    my (@params, $validatedSubTree);
    #
    # Test the XML Sub Tree to have an attribute "-language" with value "german"
    @params = (['-language', 'german']);
    $validatedSubTree = validateAttrValue($xmlSubTree, \@params);
    print "Output Test #3\n";
    dump( $validatedSubTree );
    #
    # Test the XML Sub Tree to have an attribute "-language" with value "english"
    @params = (['-language', 'english']);
    $validatedSubTree = validateAttrValue($xmlSubTree, \@params);
    print "Output Test #4\n";
    dump( $validatedSubTree );

Output:

    Output Test #1
    {
      paragraph => {
            sentence => [
                  {
                    "-language" => "english",
                    punctuation => "?",
                    words => "Do red cats eat yellow food",
                  },
                  {
                    "-language" => "english",
                    punctuation => ".",
                    words => "Brown cows eat green grass",
                  },
                ],
          },
    }
    Output Test #2
    [
      {
        "-language" => "english",
        punctuation => "?",
        words => "Do red cats eat yellow food",
      },
      {
        "-language" => "english",
        punctuation => ".",
        words => "Brown cows eat green grass",
      },
    ]
    Output Test #3
    undef
    Output Test #4
    {
      "-language" => "english",
      punctuation => "?",
      words => "Do red cats eat yellow food",
    }

=head2 Method: getSubtree

    #!/usr/bin/perl
    use XML::TreePP;
    use XML::TreePP::XMLPath qw(getSubtree);
    use Data::Dump qw(dump);
    #
    # The XML document data
    my $xmldata=<<XMLEND;
        <level1>
            <level2>
                <level3 attr1="val1" attr2="val2">
                    <attr3>val3</attr3>
                    <attr4/>
                    <attrX>one</attrX>
                    <attrX>two</attrX>
                    <attrX>three</attrX>
                </level3>
                <level3 attr1="valOne"/>
            </level2>
        </level1>
    XMLEND
    #
    # Parse the XML docuemnt.
    my $tpp = new XML::TreePP;
    my $xmldoc = $tpp->parse($xmldata);
    print "Output Test #1\n";
    dump( $xmldoc );
    #
    # Retrieve the sub tree of the XML document at path "level1/level2"
    my $xmlSubTree = getSubtree($xmldoc, 'level1/level2');
    print "Output Test #2\n";
    dump( $xmlSubTree );
    #
    # Retrieve the sub tree of the XML document at path "level1/level2/level3[@attr1='val1']"
    my $xmlSubTree = getSubtree($xmldoc, 'level1/level2/level3[@attr1="val1"]');
    print "Output Test #3\n";
    dump( $xmlSubTree );

Output:

    Output Test #1
    {
      level1 => {
            level2 => {
                  level3 => [
                        {
                          "-attr1" => "val1",
                          "-attr2" => "val2",
                          attr3    => "val3",
                          attr4    => undef,
                          attrX    => ["one", "two", "three"],
                        },
                        { "-attr1" => "valOne" },
                      ],
                },
          },
    }
    Output Test #2
    {
      level3 => [
            {
              "-attr1" => "val1",
              "-attr2" => "val2",
              attr3    => "val3",
              attr4    => undef,
              attrX    => ["one", "two", "three"],
            },
            { "-attr1" => "valOne" },
          ],
    }
    Output Test #3
    {
      "-attr1" => "val1",
      "-attr2" => "val2",
      attr3    => "val3",
      attr4    => undef,
      attrX    => ["one", "two", "three"],
    }

See validateAttrValue() EXAMPLES section for more usage examples.

=head2 Method: getAttributes

    #!/usr/bin/perl
    #
    use XML::TreePP;
    use XML::TreePP::XMLPath qw(getAttributes);
    use Data::Dump qw(dump);
    #
    # The XML document data
    my $xmldata=<<XMLEND;
        <level1>
            <level2>
                <level3 attr1="val1" attr2="val2">
                    <attr3>val3</attr3>
                    <attr4/>
                    <attrX>one</attrX>
                    <attrX>two</attrX>
                    <attrX>three</attrX>
                </level3>
                <level3 attr1="valOne"/>
            </level2>
        </level1>
    XMLEND
    #
    # Parse the XML docuemnt.
    my $tpp = new XML::TreePP;
    my $xmldoc = $tpp->parse($xmldata);
    print "Output Test #1\n";
    dump( $xmldoc );
    #
    # Retrieve the sub tree of the XML document at path "level1/level2/level3"
    my $attributes = getAttributes($xmldoc, 'level1/level2/level3');
    print "Output Test #2\n";
    dump( $attributes );
    #
    # Retrieve the sub tree of the XML document at path "level1/level2/level3[attr3=""]"
    my $attributes = getAttributes($xmldoc, 'level1/level2/level3[attr3="val3"]');
    print "Output Test #3\n";
    dump( $attributes );

Output:

    Output Test #1
    {
      level1 => {
            level2 => {
                  level3 => [
                        {
                          "-attr1" => "val1",
                          "-attr2" => "val2",
                          attr3    => "val3",
                          attr4    => undef,
                          attrX    => ["one", "two", "three"],
                        },
                        { "-attr1" => "valOne" },
                      ],
                },
          },
    }
    Output Test #2
    [{ attr1 => "val1", attr2 => "val2" }, { attr1 => "valOne" }]
    Output Test #3
    [{ attr1 => "val1", attr2 => "val2" }]

=head2 Method: getElements

    #!/usr/bin/perl
    #
    use XML::TreePP;
    use XML::TreePP::XMLPath qw(getElements);
    use Data::Dump qw(dump);
    #
    # The XML document data
    my $xmldata=<<XMLEND;
        <level1>
            <level2>
                <level3 attr1="val1" attr2="val2">
                    <attr3>val3</attr3>
                    <attr4/>
                    <attrX>one</attrX>
                    <attrX>two</attrX>
                    <attrX>three</attrX>
                </level3>
                <level3 attr1="valOne"/>
            </level2>
        </level1>
    XMLEND
    #
    # Parse the XML docuemnt.
    my $tpp = new XML::TreePP;
    my $xmldoc = $tpp->parse($xmldata);
    print "Output Test #1\n";
    dump( $xmldoc );
    #
    # Retrieve the multiple same-name elements of the XML document at path "level1/level2/level3"
    my $elements = getElements($xmldoc, 'level1/level2/level3');
    print "Output Test #2\n";
    dump( $elements );
    #
    # Retrieve the elements of the XML document at path "level1/level2/level3[attr3="val3"]
    my $elements = getElements($xmldoc, 'level1/level2/level3[attr3="val3"]');
    print "Output Test #3\n";
    dump( $elements );

Output:

    Output Test #1
    {
      level1 => {
            level2 => {
                  level3 => [
                        {
                          "-attr1" => "val1",
                          "-attr2" => "val2",
                          attr3    => "val3",
                          attr4    => undef,
                          attrX    => ["one", "two", "three"],
                        },
                        { "-attr1" => "valOne" },
                      ],
                },
          },
    }
    Output Test #2
    [
      { attr3 => "val3", attr4 => undef, attrX => ["one", "two", "three"] },
      undef,
    ]
    Output Test #3
    [
      { attr3 => "val3", attr4 => undef, attrX => ["one", "two", "three"] },
    ]

=head1 AUTHOR

Russell E Glaue, http://russ.glaue.org

=head1 SEE ALSO

XML::TreePP

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008 Center for the Application of Information Technologies.
All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

