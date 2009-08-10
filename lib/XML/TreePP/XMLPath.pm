=pod

=head1 NAME

XML::TreePP::XMLPath - Similar to XPath, defines a path as an accessor to nodes of an XML::TreePP parsed XML Document.

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

    my $xmlsub = $tppx->filterXMLDoc( $tree , q{rss/channel/item[title="The Comprehensive Perl Archive Network"]} );
    print $xmlsub->{'link'};

Iterate through all attributes and Elements of each <item> XML element:

    my $xmlsub = $tppx->filterXMLDoc( $tree , q{rss/channel/item} );
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

A pure PERL module to compliment the pure PERL XML::TreePP module. XMLPath may
be similar to XPath, and it does attempt to conform to the XPath standard when
possible, but it is far from being fully XPath compliant.

Its purpose is to implement an XPath-like accessor methodology to nodes in a
XML::TreePP parsed XML Document. In contrast, XPath is an accessor methodology
to nodes in an unparsed (or raw) XML Document.

The advantage of using XML::TreePP::XMLPath over any other PERL implementation
of XPath is that XML::TreePP::XMLPath is an accessor to XML::TreePP parsed
XML Documents. If you are already using XML::TreePP to parse XML, you can use
XML::TreePP::XMLPath to access nodes inside that parsed XML Document without
having to convert it into a raw XML Document.

=head1 REQUIREMENTS

The following perl modules are depended on by this module:
( I<Note: Dependency on Params::Validate was removed in version 0.52> )

=over 4

=item *     XML::TreePP

=item *     Data::Dump

=back

=head1 IMPORTABLE METHODS

When the calling application invokes this module in a use clause, the following
methods can be imported into its space.

=over 4

=item *     C<parseXMLPath>

=item *     C<filterXMLDoc>

=item *     C<getValues>

=item *     C<getAttributes>

=item *     C<getElements>

=item *     C<getSubtree>

=back

Example:

    use XML::TreePP::XMLPath qw(parseXMLPath filterXMLDoc getValues getAttributes getElements getSubtree);

=head1 DEPRECATED METHODS

The following methods are deprecated in the current release.

=over 4

=item *     C<validateAttrValue>

=item *     C<getSubtree>

=back

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

Where the path "C<paragraph/sentence[@language=english]/words>" has two matches:
"C<Do red cats eat yellow food>" and "C<Brown cows eat green grass>".

Where the path "C<paragraph/sentence[@language]>" has the same previous two
matches.

Where the path "C<paragraph/sentence[2][@language=english]/words>" has one
match: "C<Brown cows eat green grass>".

And where the path "C<paragraph/sentence[punctuation=.]/words>" matches 
"C<Brown cows eat green grass>"

So that "C<[@attr=val]>" is identified as an attribute inside the
"<tag attr='val'></tag>"

And "C<[attr=val]>" is identified as a nested attribute inside the
"<tag><attr>val</attr></tag>"

And "C<[2]>" is a positional argument identifying the second node in a list
"<tag><attr>value-1</attr><attr>value-2</attr></tag>".

And "C<@attr>" identifies all nodes containing the C<@attr> attribute.
"<tag><item attr="value-A">value-1</item><item attr="value-B">value-2</item></tag>".

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
after C<XML::TreePP::parse()> parses the XML Document, the attribute name is
identified as C<-attribute_name> in the resulting parsed document.
As of version 0.52 this can be changed using the C<set(attr_prefix=>'@')>
method. It should only be changed if the XML Document is provided as already
parsed, and the attributes are represented with a value other than the default.
This document uses the default value of C<-> in its examples.

XMLPath requires attributes to be specified as C<@attribute_name> and takes care
of the conversion from C<@> to C<-> behind the scenes when accessing the
XML::TreePP parsed XML document.

Child elements on the next level of a parent element are accessible as
attributes as C<attribute_name>. This is the same format as C<@attribute_name>
except without the C<@> symbol. Specifying the attribute without an C<@> symbol
identifies the attribute as a child element of the parent element being
evaluated.

Child element values are only accessible as C<CDATA>. That is when the
element being evaluated is C<animal>, the attribute (or child element) is
C<cat>, and the value of the attribute is C<tiger>, it is presented as this:

    <jungle>
        <animal>
            <cat>tiger</cat>
        </animal>
    </jungle>

The XMLPath used to access the key=value pair of C<cat=tiger> for element
C<animal> would be as follows:

    jungle/animal[cat='tiger']

And in version 0.52, in this second case, the above XMLPath is still valid:

    <jungle>
        <animal>
            <cat color="black">tiger</cat>
        </animal>
    </jungle>

In version 0.52, the period (.) is supported as it is in XPath to represent
the current context node. As such, the following XMLPaths would also be valid:

    jungle/animal/cat[.='tiger']
    jungle/animal/cat[@color='black'][.='tiger']

One should realize that in these previous two XMLPaths, the element C<cat> is
being evaluated, and not the element C<animal> as in the first case. And will
be undesirable if you want to evaluate C<animal> for results.

To perform the same evaluation, but return the matching C<animal> node, the
following XMLPath can be used:

    jungle/animal[cat='tiger']

To evaluate C<animal> and C<cat>, but return the matching C<cat> node, the
following XMLPaths can be used:

    jungle/animal[cat='tiger']/cat
    jungle/animal/cat[.='tiger']

The first path analyzes C<animal>, and the second path analyzes C<cat>. But
both matches the same node "<cat color='black>tiger</cat>".

B<Matching attributes>

Prior to version 0.52, attributes could only be used in XMLPath to evaluate
an element for a result set.
As of version 0.52, attributes can now be matched in XMLPath to return their
values.

This next example illustrates:

    <jungle>
        <animal>
            <cat color="black">tiger</cat>
        </animal>
    </jungle>
    
    /jungle/animal/cat[.='tiger']/@color

The result set of this XMLPath would be "C<black>".

=head1 METHODS

=cut

package XML::TreePP::XMLPath;

use 5.005;
use strict;
use warnings;
use Exporter;
use Carp;
#use Params::Validate qw(:all);
use XML::TreePP;
use Data::Dump qw(pp);

BEGIN {
    use vars      qw(@ISA @EXPORT @EXPORT_OK);
    @ISA        = qw(Exporter);
    @EXPORT     = qw();
    @EXPORT_OK  = qw(&charlexsplit &getAttributes &getElements &getSubtree &parseXMLPath &filterXMLDoc &getValues);

    use vars      qw($REF_NAME);
    $REF_NAME   = "XML::TreePP::XMLPath";  # package name

    use vars      qw( $VERSION $DEBUG $TPPKEYS );
    $VERSION    = '0.55';
    $DEBUG      = 0;
    $TPPKEYS    = "force_array force_hash cdata_scalar_ref user_agent http_lite lwp_useragent base_class elem_class xml_deref first_out last_out indent xml_decl output_encoding utf8_flag attr_prefix text_node_key ignore_error use_ixhash";
}


=pod

=head2 tpp

This module is an extension of the XML::TreePP module. As such, it uses the
module in many different methods to parse XML Documents, and when the user
calls the C<set()> and C<get()> methods to set and get properties specific to
the module.

The XML::TreePP module, however, is only loaded into XML::TreePP::XMLPath when
it becomes necessary to perform the previously described requests.

To avoid having this module load the XML::TreePP module, the caller must be
sure to avoid the following:

1. Do not call the C<set()> and C<get()> methods to set or get properties
specific to XML::TreePP. Doing so will cause this module to load XML::TreePP in
order to set or get those properties. In turn, that loaded instance of 
XML::TreePP is used internally when needed in the future.

2. Do not pass in unparsed XML Documents. The caller would instead want to
parse the XML Document with C<XML::TreePP::parse()> before passing it in.
Passing in an unparsed XML document causes this module to load C<XML::TreePP>
in order to parse it for processing.

Alternately, If the caller has loaded a copy of XML::TreePP, that instance
can be assigned to be used by the instance of this module using this method.
In doing so, when XML::TreePP is needed, the instance provided is used instead
of loading another copy.

Additionally, if this module has loaded an instance of XML::TreePP, this
instance can be directly accessed or retrieved through this method.

If you want to only get the internally loaded instance of XML::TreePP, but want
to not load a new instance and instead have undef returned if an instance is not
already loaded, then use the C<get()> method.

    my $tppobj = $tppx->get( 'tpp' );
    warn "XML::TreePP is not loaded in XML::TreePP::XMLPath.\n" if !defined $tppobj;

This method was added in version 0.52

=over 4

=item * C<XML::TreePP>

An instance of XML::TreePP that this object should use instead of, when needed,
loading its own copy. If not provided, the currently loaded instance is
returned. If an instance is not loaded, an instance is loaded and then returned.

=item * I<returns>

Returns the result of setting an instance of XML::TreePP in this object.
Or returns the internally loaded instance of XML::TreePP.
Or loads a new instance of XML::TreePP and returns it.

=back

    $tppx->tpp( new XML::TreePP );  # Sets the XML::TreePP instance to be used by this object
    $tppx->tpp();  # Retrieve the currently loaded XML::TreePP instance

=cut

sub tpp(@) {
    my $self    = shift if ref($_[0]) eq $REF_NAME || undef;
    if (!defined $self) {
        return new XML::TreePP;
    } else {
        return $self->{'tpp'} = shift if @_ >= 1 && ref($_[0]) eq "XML::TreePP";
        return $self->{'tpp'} if defined $self->{'tpp'} && ref($self->{'tpp'}) eq "XML::TreePP";
        $self->{'tpp'} = new XML::TreePP;
        return $self->{'tpp'};
    }
}


=pod

=head2 set

Set the value for a property in this object instance.
This method can only be accessed in object oriented style.

This method was added in version 0.52

=over 4

=item * C<propertyname>

The property to set the value for.

=item * C<propertyvalue>

The value of the property to set.
If no value is given, the property is deleted.

=item * I<returns>

Returns the result of setting the value of the property, or the result of
deleting the property.

=back

    $tppx->set( 'attr_prefix' );  # deletes the property attr_prefix
    $tppx->set( 'attr_prefix' => '@' );  # sets the value of attr_prefix

=cut

sub set(@) {
    my $self    = shift if ref($_[0]) eq $REF_NAME || undef;
    my %args    = @_;
    while (my ($key,$val) = each %args) {
        if (($key =~ $TPPKEYS) && (defined $self)) {
            # define it in XML::TreePP
            $self->tpp->set( $key => $val );
        } else {
            if ( defined $val ) {
                $self->{$key} = $val;
            }
            else {
                delete $self->{$key};
            }
        }
    }
}


=pod

=head2 get

Retrieve the value set for a property in this object instance.
This method can only be accessed in object oriented style.

This method was added in version 0.52

=over 4

=item * C<propertyname>

The property to get the value for

=item * I<returns>

Returns the value of the property requested

=back

    $tppx->get( 'attr_prefix' );

=cut

sub get(@) {
    my $self    = shift if ref($_[0]) eq $REF_NAME || undef;
    my $key     = shift;
    if (($key =~ $TPPKEYS) && (defined $self)) {
        # get it from XML::TreePP
        $self->tpp->get( $key );
    } else {
        return $self->{$key} if exists $self->{$key};
        return undef;
    }
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
# 2. Or by calling the functions in an object oriented manor, as in:
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

An analysis method for single character boundary and start/stop tokens

=over 4

=item * C<string>

The string to analyze

=item * C<boundry_start>

The single character starting boundary separating wanted elements

=item * C<boundry_stop>

The single character stopping boundary separating wanted elements

=item * C<tokens>

A { start_char => stop_char } hash reference of start/stop tokens.
The characters in C<string> contained within a start_char and stop_char are not
evaluated to match boundaries.

=item * C<boundry_begin>

Provide "1" if the beginning of the string should be treated as a 
C<boundry_start> character.

=item * C<boundry_end>

Provide "1" if the ending of the string should be treated as a C<boundry_stop>
character.

=item * I<returns>

An array reference of elements

=back

    $elements = charlexsplit (
                        string         => $string,
                        boundry_start  => $charA,   boundry_stop   => $charB,
                        tokens         => \@tokens,
                        boundry_begin  => $char1,   boundry_end    => $char2 );

=cut

# charlexsplit
# @brief    A lexical analysis function for single character boundary and start/stop tokens
# @param    string          the string to analyze
# @param    boundry_start   the single character starting boundary separating wanted elements
# @param    boundry_stop    the single character stopping boundary separating wanted elements
# @param    tokens          a { start_char => stop_char } hash reference of start/stop tokens
# @param    boundry_begin   set to "1" if the beginning of the string should be treated as a 'boundry_start' character
# @param    boundry_end     set to "1" if the ending of the string should be treated as a 'boundry_stop' character
# @return   an array reference of the resulting parsed elements
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
    my %args            = @_;
    my @warns;
    push(@warns,'string')           if !defined $args{'string'};
    push(@warns,'boundry_start')    if !exists $args{'boundry_start'};
    push(@warns,'boundry_stop')     if !exists $args{'boundry_stop'};
    push(@warns,'tokens')           if !exists $args{'tokens'};
    if (@warns) { carp ('method charlexsplit(@) requires the arguments: '.join(', ',@warns).'.'); return undef; }
    #my %args    =   validate ( @_,  {   string          => { type => SCALAR,   optional => 0 },
    #                                    boundry_start   => { type => SCALAR,   optional => 0 },
    #                                    boundry_stop    => { type => SCALAR,   optional => 0 },
    #                                    tokens          => { type => ARRAYREF, optional => 0 },
    #                                    boundry_begin   => { type => SCALAR,   optional => 1 },
    #                                    boundry_end     => { type => SCALAR,   optional => 1 }
    #                                }
    #                         );

    my $string          = $args{'string'};        # The string to parse
    my $boundry_start   = $args{'boundry_start'}; # The boundary character separating wanted elements
    my $boundry_stop    = $args{'boundry_stop'};  # The boundary character separating wanted elements
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
                if ($boundry_start ne $boundry_stop) {  # -and the start and stop boundaries are different
                    $collect = 0;                       # -turn off collection
                } else {
                    $collect = 1;                       # -but keep collection on if the boundaries are the same
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

Parse a string that represents the XMLPath to a XML element or attribute in a
XML::TreePP parsed XML Document.

Note that the XML attributes, known as "@attr" are transformed into "-attr".
The preceding (-) minus in place of the (@) at is the recognized format of
attributes in the XML::TreePP module.

Being that this is intended to be a submodule of XML::TreePP, the format of 
'@attr' is converted to '-attr' to conform with how XML::TreePP handles
attributes.

See: XML::TreePP->set( attr_prefix => '@' ); for more information.
This module supports the default format, '-attr', of attributes. But as of
version 0.52 this can be changed by setting this modules 'attr_prefix' property
using the C<set()> method in object oriented programming.
Example:

    my $tppx = new XML::TreePP::XMLPath();
    $tppx->set( attr_prefix => '@' );

B<XMLPath Filter by index and existence>
Also, as of version 0.52, there are two additional types of XMLPaths understood.

I<XMLPath with indexes, which is similar to the way XPath does it>

    $path = '/books/book[5]';

This defines the fifth book in a list of book elements under the books root.
When using this to get the value, the 5th book is returned.
When using this to test an element, there must be 5 or more books to return true.

I<XMLPath by existence, which is similar to the way XPath does it>

    $path = '/books/book[author]';

This XMLPath represents all book elements under the books root which have 1 or
more author child element. It does not evaluate if the element or attribute to
evaluate has a value. So it is a test for existence of the element or attribute.

=over 4

=item * C<XMLPath>

The XML path to be parsed.

=item * I<returns>

An array reference of array referenced elements of the XMLPath.

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
# Where the path 'paragraph/sentence[@language=english]/words' matches 'Do red cats eat yellow food'
# (Note this is because it is the first element of a multi element match)
# And the path 'paragraph/sentence[punctuation=.]/words' matches 'Brown cows eat green grass'
# So that '@attr=val' is identified as an attribute inside the <tag attr=val></tag>
# And 'attr=val' is identified as a nested attribute inside the <tag><attr>val</attr></tag>
#
# Note the format of '@attr' is converted to '-attr' to conform with how XML::TreePP handles this
#
sub parseXMLPath ($) {
    my $self        = shift if ref($_[0]) eq $REF_NAME || undef;
    if (@_ != 1) { carp 'method parseXMLPath($) requires one argument.'; return undef; }
    #validate_pos( @_, 1);
    my $path        = shift;
    my $hpath       = [];
    my ($tpp,$xml_text_id,$xml_attr_id);

    if ((defined $self) && (defined $self->get('tpp'))) {
        $tpp         = $self ? $self->tpp() : tpp();
        $xml_text_id = $tpp->get( 'text_node_key' ) || '#text';
        $xml_attr_id = $tpp->get( 'attr_prefix' )   || '-';
    } else {
        $xml_text_id = '#text';
        $xml_attr_id = '-';
    }

    my $h_el = charlexsplit   (
        string        => $path,
        boundry_start => '/',
        boundry_stop  => '/',
        tokens        => [qw( [ ] ' ' " " )],
        boundry_begin => 1,
        boundry_end   => 1
        );
    foreach my $el (@{$h_el}) {
        # See: XML::TreePP->set( attr_prefix => '@' );, where default is '-'
        $el =~ s/^\@/$xml_attr_id/;
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
                my ($attr,$val);
                #
                # define string values here
                # defined first, as string is recognized as the default
                ($attr,$val) = $param =~ /([^\=]*)\=[\'\"]?(.*[^\'\"])[\'\"]?/;
                if ((! defined $attr) && (! defined $val)) {
                    ($attr) = $param =~ /([^\=]*)\=[\'\"]?[\'\"]?/;
                    $val = '';
                }
                if ((! defined $attr) && (! defined $val)) {
                    ($attr) = $param =~ /^([^\=]*)$/;
                    $val = undef;
                }
                #
                # define literal values here, which are not string-values
                # defined second, as literals are strictly defined
                if ($param =~ /^(\d*)$/) {
                    # It is a positional argument, ex: /books/book[3]
                    $attr = $1;
                    $val  = undef;
                } elsif ($param =~ /^([^\=]*)$/) {
                    # Only the element/attribute is defined, ex: /path[@attr]
                    $attr = $1;
                    $val  = undef;
                }
                #
                # Internal - convert the attribute identifier
                # See: XML::TreePP->set( attr_prefix => '@' );, where default is '-'
                $attr =~ s/^\@/$xml_attr_id/;
                #
                # push the result
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

=head2 filterXMLDoc

To filter down to a subtree or set of subtrees of an XML document based on a
given XMLPath

This method can also be used to determine if a node within an XML tree is valid
based on the given filters in an XML path.

This method replaces the two methods C<getSubtree()> and C<validateAttrValue()>.

This method was added in version 0.52

=over 4

=item * C<XMLDocument>

The XML document tree, or subtree node to validate.
This is an XML document either given as plain text string, or as parsed by the
C<XML::TreePP->parse()> method.

The XMLDocument, when parsed, can be an ARRAY of multiple elements to evaluate,
which would be validated as follows:

    # when path is: context[@attribute]
    # returning: $subtree[item] if valid (returns all validated [item])
    $subtree[item]->{'-attribute'} exists
    # when path is: context[@attribute="value"]
    # returning: $subtree[item] if valid (returns all validated [item])
    $subtree[item]->{'-attribute'} eq "value"
    $subtree[item]->{'-attribute'}->{'value'} exists
    # when path is: context[5]
    # returning: $subtree[5] if exists (returns the fifth item if validated)
    $subtree['itemnumber']
    # when path is: context[5][element="value"]
    # returning: $subtree[5] if exists (returns the fifth item if validated)
    $subtree['itemnumber']->{'element'} eq "value"
    $subtree['itemnumber']->{'element'}->{'value'} exists

Or the XMLDocument can be a HASH which would be a single element to evaluate.
The XMLSubTree would be validated as follows:

    # when path is: context[element]
    # returning: $subtree if validated
    $subtree{'element'} exists
    # when path is: context[@attribute]
    # returning: $subtree if validated
    $subtree{'-attribute'} eq "value"
    $subtree{'-attribute'}->{'value'} exists

=item * C<XMLPath>

The path within the XML Tree to retrieve. See C<parseXMLPath()>

=item * I<returns>

The parsed XML Document subtrees that are validated, or undef if not validated

You can retrieve the result set in one of two formats.

    # Option 1 - An ARRAY reference to a list
    my $result = filterXMLDoc( $xmldoc, '/books' );
    # $result is:
    # [ { book => { title => "PERL", subject => "programming" } },
    #   { book => { title => "All About Backpacks", subject => "hiking" } } ]
    
    # Option 2 - A list, or normal array
    my @result = filterXMLDoc( $xmldoc, '/books/book[subject="camping"]' );
    # $result is:
    # ( { title => "campfires", subject => "camping" },
    #   { title => "tents", subject => "camping" } )

=back

    my $result = filterXMLDoc( $XMLDocument , $XMLPath );
    my @result = filterXMLDoc( $XMLDocument , $XMLPath );

=cut

sub filterXMLDoc ($$) {
    my $self        = shift if ref($_[0]) eq $REF_NAME || undef;
    if (@_ != 2) { carp 'method filterXMLDoc($$) requires two arguments.'; return undef; }
    #validate_pos( @_, 1, 1);
    my $tree        = shift || (carp 'filterXMLDoc($$) requires two arguments.' && return undef);
    my $path        = shift || (carp 'filterXMLDoc($$) requires two arguments.' && return undef);
    my ($tpp,$xtree,$xpath,$xml_text_id,$xml_attr_id);

    if (ref $tree) { $xtree       = $tree;
                     $xml_text_id = '#text';
                     $xml_attr_id = '-';
                   }
              else { $tpp         = $self ? $self->tpp() : tpp();
                     $xtree       = $tpp->parse($tree);
                     $xml_text_id = $tpp->get( 'text_node_key' ) || '#text';
                     $xml_attr_id = $tpp->get( 'attr_prefix' )   || '-';
                   }
    if (ref $path) { $xpath       = $path;
                   }
              else { $xpath       = parseXMLPath($path);
                   }

    # This is used on the lowest level of an element, and is the
    # execution of our rules for matching or validating a value
    my $validateFilter = sub (@) {
        my %args            = @_;
        print ("="x8,"sub:filterXMLDoc|validateFilter->()\n") if $DEBUG;
        print (" "x8,"= attempting to validate filter, with: ", pp(\%args) ,"\n") if $DEBUG;
        # we accept:
        # - required: node,param,comparevalue ; optional: operand(=) (= is default)
        # not accepted: - required: node,param,operand(exists)
        return 0 if !exists $args{'node'} || !exists $args{'comparevalue'};
        # Node possibilities this method is expecting to see:
        # VALUE: 'Henry'                        -asin-> { people => { person => 'Henry' } }
        # VALUE: [ 'Henry', 'Sally' ]           -asin-> { people => { person => [ 'Henry', 'Sally' ] } }
        # VALUE: { id => 45, #text => 'Henry' } -asin-> { people => { person => { id => 45, #text => 'Henry' } } }
        # Also, comparevalue could be '', an empty string
        # comparevalue of undef is attempted to be matched here, because operand defaults to "eq" or "="
        if (ref $args{'node'} eq "HASH") {
            if (exists $args{'node'}->{$xml_text_id}) {
                return 1 if defined $args{'node'}->{$xml_text_id} && defined $args{'comparevalue'} && $args{'node'}->{$xml_text_id} eq "" && $args{'comparevalue'} eq "";
                return 1 if !defined $args{'node'}->{$xml_text_id} && !defined $args{'comparevalue'};
                return 1 if $args{'node'}->{$xml_text_id} eq $args{'comparevalue'};
            }
        } elsif (ref $args{'node'} eq "ARRAY") {
            foreach my $value (@{$args{'node'}}) {
                if (ref $value eq "HASH") {
                    if (exists $value->{$xml_text_id}) {
                        return 1 if defined $value->{$xml_text_id} && defined $args{'comparevalue'} && $value->{$xml_text_id} eq "" && $args{'comparevalue'} eq "";
                        return 1 if !defined $value->{$xml_text_id} && !defined $args{'comparevalue'};
                        return 1 if $value->{$xml_text_id} eq $args{'comparevalue'};
                    }
                } else {
                    return 1 if defined $value && defined $args{'comparevalue'} && $value eq "" && $args{'comparevalue'} eq "";
                    return 1 if !defined $value && !defined $args{'comparevalue'};
                    return 1 if $value eq $args{'comparevalue'};
                }
            }
        } elsif (ref $args{'node'} eq "SCALAR") { # not likely -asin-> { people => { person => \$value } }
            return 1 if defined ${$args{'node'}} && defined $args{'comparevalue'} && ${$args{'node'}} eq "" && $args{'comparevalue'} eq "";
            return 1 if !defined ${$args{'node'}} && !defined $args{'comparevalue'};
            return 1 if ${$args{'node'}} eq $args{'comparevalue'};
        } else {  # $node =~ /\w/
            return 1 if defined $args{'node'} && defined $args{'comparevalue'} && $args{'node'} eq "" && $args{'comparevalue'} eq "";
            return 1 if !defined $args{'node'} && !defined $args{'comparevalue'};
            return 1 if $args{'node'} eq $args{'comparevalue'};
        }
        return 0;
    }; #end validateFilter->();

    # So what do we support as filters
    # /books/book[@id="value"]      # attribute eq value
    # /books/book[title="value"]    # element eq value
    # /books/book[@type]            # Attribute exists
    # /books/book[author]           # element exists
    # Not yet: /books/book[publisher/address/city="value"]   # sub/child element eq value
    # And what are some of the things we do not support
    # /books/book[publisher/address[country="US"]/city="value"]   # sub/child element eq value based on another filter
    # /books/book[5][./title=../book[4]/title]  # comparing the values of two elements
    my $processFilters = sub ($$) {
        print ("="x8,"sub:filterXMLDoc|processFilters->()\n") if $DEBUG;
        my $xmltree_child           = shift;
        my $filters                 = shift;
        my $filters_processed_count = 0; # Will catch a filters error of [[][][]] or something
        my $param_match_flag        = 0;
        FILTER: foreach my $filter (@{$filters}) {
            next if !defined $filter; # if we get empty filters;
            $filters_processed_count++;

            my $param = $filter->[0];
            my $value = $filter->[1];
            print (" "x8,"= processing filter: " . $param) if $DEBUG;
            print (" , " . $value) if defined $value && $DEBUG;
            print ("\n") if $DEBUG;

            # attribute/element exists filter
            if (($param ne ".") && (! exists $xmltree_child->{$param})) {
                $param_match_flag = 0;
                last FILTER;
            } elsif ((($param eq ".") || (exists $xmltree_child->{$param})) && (! defined $value)) {
                # NOTE, maybe filter needs to be [['attr'],['attr','val']] for this one
                $param_match_flag = 1;
                next FILTER;
            }

            print (" "x12,"= about to validate filter.\n") if $DEBUG;
            if (     ($param ne ".") &&
                     ($validateFilter->( node => $xmltree_child->{$param},
                                      operand => '=',
                                 comparevalue => $value))
                ) {
                print (" "x12,"= validated filter.\n") if $DEBUG;
                $param_match_flag = 1;
                next FILTER;
            } elsif (($param eq ".") &&
                     ($validateFilter->( node => $xmltree_child,
                                      operand => '=',
                                 comparevalue => $value))
                ) {
                print (" "x12,"= validated filter.\n") if $DEBUG;
                $param_match_flag = 1;
                next FILTER;
            } else {
                print (" "x12,"= unvalidated filter.\n") if $DEBUG;
                $param_match_flag = 0;
                last FILTER;
            }

            # Examples of what $xmltree_child->{$param} can be
            # (Perhaps this info should be bundled with $validateFilter->() method)
            # 1. A SCALAR ref will probably never occur
            # 2a. An ARRAY ref of strings
            #    PATH: /people[person='Henry']
            #    XML: <people><person>Henry</person><person>Sally</person></people>
            #    PARSED: { people => { person => [ 'Henry', 'Sally' ] } }
            # 2b. or ARRAY ref or HASH refs
            #    XML: <people><person id='1'>Henry</person><person id='2'>Sally</person></people>
            #    PARSED: { people => { person => [ { id => 1, #text => 'Henry' }, { id => 2, #text => 'Sally' } ] } }
            # 3. A HASH when in cases like this:
            #    PATH: /people/person[@id=45]
            #    XML: <people><person id="45">Henry</person></people>
            #    PARSED: { people => { person => { id => 45, #text => 'Henry' } } }
            # 4. The most likely encounter of plain old text/string values
            #    PATH: /people/person
            #    XML: <people><person>Henry</person></people>
            #    PARSED: { people => { person => 'Henry' } }

        } #end FILTER
        if ($filters_processed_count == 0) {
            # there was some unusual error which caused a lot of undef filters
            # And as such, $param_match_flag will be 0
            # we return the entire tree as valid
            return $xmltree_child;
        } elsif ($param_match_flag == 0) {
            # filters were processed, but there was no matches
            # we return undef because nothing validated
            return undef;
        } else {
            return $xmltree_child;
        }
    }; #end processFilters->()

    my $find = sub (@) {};
    $find = sub (@) {
        my $xmltree         = shift;  # The parsed XML::TreePP tree
        my $xmlpath         = shift;  # The parsed XML::TreePP::XMLPath path
        my $xmltree_parent  = shift || undef;
        print ("="x8,"sub::filterXMLDoc|_find()\n") if $DEBUG;
        print (" "x8,"= attempting to find path: ", pp($xmlpath) ,"\n") if $DEBUG;
        print (" "x8,"= attempting to search in: ", pp($xmltree) ,"\n") if $DEBUG;

        # If there are no more path to analyze, return
        if ((ref($xmlpath) ne "ARRAY") || (! @{$xmlpath} >= 1)) {
            print (" "x8,"= end of path reached\n") if $DEBUG;
            return $xmltree;
        }

        my @found;
        # First determine if we are analyzing one of three possible formats of
        # the current context:
        # HASH ref   - $xmltree = {}
        # ARRAY ref  - $xmltree = []
        # SCALAR ref - ${$xmltree} =~ /\w/
        # SCALAR     - $xmltree =~ /\w/
        if (ref $xmltree eq "HASH") {
            print (" "x12,"= search tree is HASH\n") if $DEBUG;
            my $path_element    = shift @{$xmlpath};
            my $element         = shift @{$path_element};
            my $filters         = shift @{$path_element};
            my $xmltree_context = $xmltree;
            my $xmltree_child;

            # xmltree_context is the current node we are evaluating
            # xmltree_child is the next node we are going to descend to
            # xmltree_parent is the node we just descended from, or the xmltree_context of the caller $find->()

            # Do not continue if the desired element in the path does not exist
            # But if the element refers to an existing subtree, current context,
            # or the parent, lets deal with it
            print (" "x12,"= processing element ".$element."\n") if $DEBUG;
            if ((defined $element) && ($element eq '..')) {
                if (defined $xmltree_parent) {
                    $xmltree_context = $xmltree_parent;
                    $xmltree_parent = undef;
                }
            } elsif ((defined $element) && ($element eq '.')) {
                $xmltree_child = $xmltree_context;
            } elsif ((defined $element) && (!exists $xmltree_context->{$element})) {
                return undef;
            } elsif ((defined $element) && (exists $xmltree_context->{$element})) {
                $xmltree_child = $xmltree_context->{$element};
            }

            # Process the first filter, if it exists, for positional testing
            # If a positional argument is given, shift to the item located at
            # that position
            # Yes, this does mean the positional argument must be the first filter.
            # But then again, this would not make clear sense: /books/book[author="smith"][5]
            # And this path makes more clear sense: /books/book[5][author="smith"]
            if ( (defined $filters)              &&
                 ($filters->[0]->[0] =~ /^\d*$/) &&
                 (! defined $filters->[0]->[1])  &&
                 ($filters->[0]->[0] >= 0) ) {
                print (" "x12,"= processing list position filter.\n") if $DEBUG;
                my $lpos            = shift @{$filters};
                my $position        = $lpos->[0] if $lpos >= 1;
                # context must be multi-valued foo positional arguments to work.
                # but we make the exception if the positional argument is "1"
                # which we interpret as the current single context item
                if (($position > 1) && (ref($xmltree_child) ne "ARRAY")) {
                    return undef;
                } elsif (ref($xmltree_child) eq "ARRAY") {
                    print (" "x12,"= looking up position ",$position,"\n") if $DEBUG;
                    # Should I instead check first?
                    # return undef if $position > @{$subtree_context};
                    $xmltree_child  = $xmltree_child->[($position - 1)] || return undef;
                }
            }

            if ((!defined $filters) || (@{$filters} < 1)) {
                print (" "x12,"= no more filters.\n") if $DEBUG;
                # If there are no more filters to process, we descend
                return $find->($xmltree_child,$xmlpath,$xmltree_context);
            } else {
                print (" "x12,"= processing remaining filters.\n") if $DEBUG;
                # If more filters, process each of them


                # There is only one possible match with filters against a node,
                # because of the limitation of filters we accept.
                # This will change if we accept filters similar to something like this:
                # /books/book[@id > 5]  # any book with attribute id value greater than 5
                # /books/book[author="*smith*"]  # any book with element author containing "smith"

                if (ref($xmltree_child) eq "ARRAY") {
                    my @xmltrees;
                    foreach my $sub (@{$xmltree_child}) {
                    print (" "x12,"= search tree descendant is ARRAY.\n") if $DEBUG;
                        # First make a copy of the $filters to pass in
                        my $tmpfilters = eval ( pp($filters) );
                        my $vtree = $processFilters->($sub,$tmpfilters);
                        push (@xmltrees, $vtree) if defined $vtree;
                    }
                    if (@xmltrees >= 1) {
                        return $find->(\@xmltrees,$xmlpath,$xmltree_context);
                    }
                } else {
                    print (" "x12,"= search tree descendant is NOT ARRAY.\n") if $DEBUG;
                    my $vtree = $processFilters->($xmltree_child,$filters);
                    # filters were processed with matches
                    if (defined $vtree) {
                        return $find->($xmltree_child,$xmlpath,$xmltree_context);
                    }
                }
                return undef;
            }

        } elsif (ref $xmltree eq "ARRAY") {
            print (" "x12 , "= search tree is ARRAY\n") if $DEBUG;
            foreach my $sub (@{$xmltree}) {
                # First make a copy of the $xmlpath to pass in
                my $tmpxmlpath = eval ( pp($xmlpath) );
                my $xmltree_tmp = $find->($sub,$tmpxmlpath);
                if (ref $xmltree_tmp eq "ARRAY") {
                    print (" "x12,"= search tree result is ARRAY\n") if $DEBUG;
                    foreach my $xt (@{$xmltree_tmp}) {
                        push (@found,$xt) if defined $xt;
                    }
                } else {
                    print (" "x12,"= search tree result is NOT ARRAY\n") if $DEBUG;
                    push (@found,$xmltree_tmp) if defined $xmltree_tmp;
                }
            }
            return \@found;
        } elsif (ref $xmltree eq "SCALAR") {
            # We have more path to analyze, but no more depth to our xml doc
            # do not - push (@found,${$xmltree});
            # do nothing
        } else {  # subtree is text, or some other unrecognized reference
            # We have more path to analyze, but no more depth to our xml doc
            # do not - push (@found,$xmltree);
            # do nothing
        }
        return undef;  # $xmltree is unrecognized
    }; # end find->()

    my $found = $find->($xtree,$xpath,$xtree);
    $found = [$found] if ref $found ne "ARRAY";
    return undef if (! defined $found || @{$found} == 0) && !defined wantarray;
    return (@{$found}) if !defined wantarray;
    return wantarray ? @{$found} : $found;
}


=pod

=head2 getValues

Retrieve the values found in the given XML Document at the given XMLPath.

This method was added in version 0.53 as getValue, and changed to getValues in 0.54

=over 4

=item * C<XMLDocument>

The XML Document to search and return values from.

=item * C<XMLPath>

The XMLPath to retrieve the values from.

=item * C<valstring => 1|0>

Return values that are strings. (default is 1)

=item * C<valxml => 1|0>

Return values that are xml, as raw xml. (default is 0)

=item * C<valxmlparsed => 1|0>

Return values that are xml, as parsed xml. (default is 0)

=item * C<valtrim => 1|0>

Trim off the white space at the beginning and end of each value in the result
set before returning the result set. (default is 0)

=item * I<returns>

Returns the values from the XML Document found at the XMLPath.

=back

    # return the value of @author from all book elements
    $vals = $tppx->getValues( $xmldoc, '/books/book/@author' );
    # return the values of the current node, or XML Subtree
    $vals = $tppx->getValues( $xmldoc_node, "." );
    # return only XML data from the 5th book node
    $vals = $tppx->getValues( $xmldoc, '/books/book[5]', valstring => 0, valxml => 1 );
    # return only XML::TreePP parsed XML from the all book nodes having an id attribute
    $vals = $tppx->getValues( $xmldoc, '/books/book[@id]', valstring => 0, valxmlparsed => 1 );
    # return both unparsed XML data and text content from the 3rd book excerpt,
    # and trim off the white space at the beginning and end of each value
    $vals = $tppx->getValues( $xmldoc, '/books/book[3]/excerpt', valstring => 1, valxml => 1, valtrim => 1 );

=cut

sub getValues (@) {
    my $self        = shift if ref($_[0]) eq $REF_NAME || undef;
    if (@_ < 2) { carp 'method getValues(@) requires at least two arguments.'; return undef; }
    #validate_pos( @_, 1, 1);
    my $tree        = shift;
    my $path        = shift;
    # Supported arguments:
    # valstring = 1|0    ; default = 1; 1 = return values that are strings
    # valxml = 1|0       ; default = 0; 1 = return values that are xml, as raw xml
    # valxmlparsed = 1|0 ; default = 0; 1 = return values that are xml, as parsed xml
    my %args        = @_;
    my $v_string    = exists $args{'valstring'}    ? $args{'valstring'}    : 1;
    my $v_xml       = exists $args{'valxml'}       ? $args{'valxml'}       : 0;
    my $v_xmlparsed = exists $args{'valxmlparsed'} ? $args{'valxmlparsed'} : 0;
    my $v_trim      = exists $args{'valtrim'}      ? $args{'valtrim'}      : 0;
    # Make up this code to dictate allowed combinations of return types
    my $v_ret_type  = "sp"  if $v_string && $v_xmlparsed;
       $v_ret_type  = "sx"  if $v_string && $v_xml;
       $v_ret_type  = "s"   if $v_string && ! $v_xml && ! $v_xmlparsed;
       $v_ret_type  = "p"   if ! $v_string && $v_xmlparsed;
       $v_ret_type  = "x"   if ! $v_string && $v_xml;

    my ($tpp,$xtree,$xpath,$xml_text_id,$xml_attr_id,$old_prop_xml_decl);

    if (ref $tree) { $xtree       = $tree;
                     $xml_text_id = '#text';
                     $xml_attr_id = '-';
                   }
              else { $tpp         = $self ? $self->tpp() : tpp();
                     $xtree       = $tpp->parse($tree);
                     $xml_text_id = $tpp->get( 'text_node_key' ) || '#text';
                     $xml_attr_id = $tpp->get( 'attr_prefix' )   || '-';
                   }
    if (ref $path) { $xpath       = $path;
                   }
              else { $xpath       = parseXMLPath($path);
                   }
    if ($v_ret_type =~ /x/) {
        if (ref($tpp) ne "XML::TreePP") {
            $tpp = $self ? $self->tpp() : tpp();
        }
        # $tpp->set( indent => 2 );
        $old_prop_xml_decl = $tpp->get( "xml_decl" );
        $tpp->set( xml_decl => '' );
    }

    print ("="x8,"sub::getValues()\n") if $DEBUG;
    print (" "x8, "=called with return type: ",$v_ret_type,"\n") if $DEBUG;
    print (" "x8, "=called with path: ",pp($xpath),"\n") if $DEBUG;

    # Retrieve the sub tree of the XML document at path
    my $results = filterXMLDoc($xtree, $xpath);

    # for debugging purposes
    print (" "x8, "=Found at var's path: ", pp( $results ),"\n") if $DEBUG;

    my $getVal = sub ($) {};
    $getVal = sub ($) {
        print ("="x8,"sub::getValues|getVal->()\n") if $DEBUG;
        my $treeNodes = shift;
        print (" "x8,"getVal-from> ",pp($treeNodes)) if $DEBUG;
        print (" - '",ref($treeNodes)||'string',"'\n") if $DEBUG;
        my @results;
        if (ref($treeNodes) eq "HASH") {
            my $utreeNodes = eval ( pp($treeNodes) ); # make a copy for the result set
            push (@results, $utreeNodes->{$xml_text_id}) if exists $utreeNodes->{$xml_text_id} && $v_ret_type =~ /s/;
            delete $utreeNodes->{$xml_text_id} if exists $utreeNodes->{$xml_text_id} && $v_ret_type =~ /[x,p]/;
            push (@results, $utreeNodes) if $v_ret_type =~ /p/;
            push (@results, $tpp->write($utreeNodes)) if $v_ret_type =~ /x/;
        } elsif (ref($treeNodes) eq "ARRAY") {
            foreach my $item (@{$treeNodes}) {
                my $r1 = $getVal->($item);
                foreach my $r2 (@{$r1}) {
                    push(@results,$r2) if defined $r2;
                }
            }
        } elsif (! ref($treeNodes)) {
            push(@results,$treeNodes) if $v_ret_type =~ /s/;
        }
        return \@results;
    };

    if ($v_ret_type =~ /x/) {
        $tpp->set( xml_decl => $old_prop_xml_decl );
    }

    my $found = $getVal->($results);
    $found = [$found] if ref $found ne "ARRAY";

    if ($v_trim) {
        my $i=0;
        while($i < @{$found}) {
            print ("        =trimmimg result (".$i."): '",$found->[$i],"'") if $DEBUG;
            $found->[$i] =~ s/\s*$//g;
            $found->[$i] =~ s/^\s*//g;
            print (" to '",$found->[$i],"'\n") if $DEBUG;
            $i++;
        }
    }

    return undef if (! defined $found || @{$found} == 0) && !defined wantarray;
    return (@{$found}) if !defined wantarray;
    return wantarray ? @{$found} : $found;
}


=pod

=head2 validateAttrValue

As of version 0.52, this method is deprecated. The method C<filterXMLDoc()>
should be used instead. See this method's implementation illustration for the
alternate example using C<filterXMLDoc()>.

Validate a subtree of a parsed XML document to have a parameter set in which
an attribute matches a value.

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

As of XMLPath version 0.52, one can define an element or attribute existence
test with the parsed results from the C<parseXMLPath()> method. This feature
was already available in this method before 0.52, but C<parseXMLPath()> did
not provide it from the results of parsing a XMLPath until version 0.52.
The result of parsing this with C<parseXMLPath()> for use by this method is as
follows:

    my $params = [[ "-id", undef ]];  # Test for existence of the attribute "id"
                                      # as in this path: /books/book[@id]

=item * I<returns>

The subtree that is validated, or undef if not validated

=back

    my @params = ( [ "element", "value" ], [ "-attribute", "value" ] );
    $validatedXMLTree = validateAttrValue( $XMLTree , \@params );

    # Alternately, you can do the same using the filterXMLDoc() method using
    # the single period (.) which identifies the immediate root of the
    # XML Document (or a XML Document node you provide instead).
    # If $XMLTree can be either plain text or a XML::TreePP parsed XML Document
    my $result = filterXMLDoc( $XMLTree, '[.[element="value"][@attribute="value"]]' );
    my $result = filterXMLDoc( $XMLTree, [ ".", \@params ] );

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
# individually for validating.
#
sub validateAttrValue ($$);
sub validateAttrValue ($$) {
    my $self        = shift if ref($_[0]) eq $REF_NAME || undef;
    if (@_ != 2) { carp 'method validateAttrValue($$) requires two arguments.'; return undef; }
    #validate_pos( @_, 1, 1);
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
                # If SCALAR, val is defined, and attr=val
                $param_match_flag = 1;
                next PARAM;
            } elsif (   (ref    $subtree->{$attribute} eq "SCALAR" )
                     && (! defined              $value             )
                     && (! defined ${$subtree->{$attribute}}       ) ) {
                # If SCALAR, val is NOT defined, and ref(attr) is undef
                $param_match_flag = 1;
                next PARAM;
            } elsif (   (ref    $subtree->{$attribute} eq "SCALAR" )
                     && (                       $value eq ''       )
                     && (    ${$subtree->{$attribute}} eq ''       ) ) {
                # If SCALAR, val is defined as empty string, and attr=val
                $param_match_flag = 1;
                next PARAM;
            } elsif (   (ref    $subtree->{$attribute} eq "HASH"   )
                     && (! defined              $value             ) ) {
                # If HASH, val is NOT defined -> existence test
                $param_match_flag = 1;
                next PARAM;
            } elsif (   (ref    $subtree->{$attribute} eq "HASH"   )
                     && (defined                $value             )
                     && (exists $subtree->{$attribute}->{$value}   ) ) {
                # If HASH, val is defined, and val exists as a hash key
                $param_match_flag = 1;
                next PARAM;
            } elsif (    ref    $subtree->{$attribute} eq "ARRAY"  )   {
                # we are looking at a ARRAY value
                foreach my $a_subtree (@{$subtree->{$attribute}}) {
                    if      (   (! defined     $value          )
                             && (! defined $a_subtree          )) {
                        $param_match_flag = 1;
                        next PARAM;
                    } elsif (   (  defined     $value          )
                             && (              $value eq ''    )
                             && (  defined $a_subtree          )
                             && (          $a_subtree eq ''    )) {
                        $param_match_flag = 1;
                        next PARAM;
                    } elsif (   (  defined     $value          )
                             && (  defined $a_subtree          )
                             && (          $a_subtree eq $value)) {
                        $param_match_flag = 1;
                        next PARAM;
                    }
                }
                $param_match_flag = 0;
                last PARAM;
            } else {
                # we are looking at a string value
                if      (   (! defined $value                      )
                         && (! defined $subtree->{$attribute}      )) {
                    $param_match_flag = 1;
                } elsif     (! defined $value                      )  {
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

As of version 0.52, this method is deprecated. The function C<filterXMLDoc()>
should be used instead. See this method's implementation illustration for the
alternate example using C<filterXMLDoc()>.

Starting in version 0.52, this method still returns the
same single value as it did in version 0.51, but with additional filtering
capabilities provided to it by C<filterXMLDoc()> . Also starting in version
0.52 this method can additionally return an array of values resulting from the
match. See I<returns> below.

Return a subtree of an XML tree from a given XMLPath.
See C<parseXMLPath()> for the format of a XMLPath.
This function returns the first subtree or an array of subtrees in the given
XML tree found to match the given XMLPath.

If you want to retrieve all subtrees in the given XML tree which match the given
XML path, you should ideally use the C<filterXMLDoc()> function.

This method actually executes C<filterXMLDoc()> and returns the first result
set, or more precisely the first matching node and its subtree in the XML Doc.
If the context of the caller is requesting a list or array, then all matching
nodes and their subtrees will be returned to the caller as a list (array).

=over 4

=item * C<XMLTree>

An XML::TreePP parsed XML document.

=item * C<XMLPath>

The path within the XML Tree to retrieve. See parseXMLPath()

=item * I<returns>

A subtree of a XML::TreePP parsed XMLTree found at the XMLPath and the caller
is not requesting an array, otherwise a list of subtrees are returned.
Depending on the XMLPath given, the returning value(s) could actually be string
values and not referenced subtree nodes.

=back

    $XMLSubTree = getSubtree ( $XMLTree , $XMLPath );
    @XMLSubTrees = getSubtree ( $XMLTree , $XMLPath );

    # Alternately, you can do the same using the filterXMLDoc() method.
    my $result = filterXMLDoc( $XMLTree, $XMLPath );
    my @result = filterXMLDoc( $XMLTree, $XMLPath );

=cut

# getSubtree
# @brief  return a subtree of an XML tree from a given path (see parseXMLPath)
# @param    xmltree     the XML tree
# @param    xmlpath     the path within the XML Tree to retrieve (see parseXMLPath)
# @return   a subtree of the XMLTree from the given XMLPath
sub getSubtree ($$) {
    my $self        = shift if ref($_[0]) eq $REF_NAME || undef;
    if (@_ != 2) { carp 'method getSubtree($$) requires two arguments.'; return undef; }
    #validate_pos( @_, 1, 1);
    my $tree        = shift;
    my $path        = shift;

    my $result = filterXMLDoc($tree,$path);
    return undef unless defined $result;
    return wantarray ? @{$result} : $result->[0];
}

=pod

=head2 getAttributes

=over 4

=item * C<XMLTree>

An XML::TreePP parsed XML document.

=item * C<XMLPath>

The path within the XML Tree to retrieve. See parseXMLPath()

=item * I<returns>

An array reference of [{attribute=>value}], or undef if none found

In the case where the XML Path points at a multi-same-name element, the return
value is a ref array of ref hashes, one hash ref for each element.

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
# @param    xmlpath     the XML path (See parseXMLPath)
# @return   an array ref of [{attr=>val, attr=>val}], or undef if none found
#
# In the case where the XML Path points at a multi-same-name element, the
# return value is a ref array of ref arrays, one for each element.
# Example:
#  XML Path points at a single named element
#  [{attr1=>val, attr2=>val}]
#  XML Path points at a multi-same-name element
#  [ {attr1A=>val,attr1B=>val}, {attr2A=>val,attr2B=val} ]
#
sub getAttributes (@);
sub getAttributes (@) {
    my $self        = shift if ref($_[0]) eq $REF_NAME || undef;
    unless (@_ >= 1) { carp 'method getAttributes($$) requires one argument, and optionally a second argument.'; return undef; }
    # validate_pos( @_, 1, 0);
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

An array reference of [{element=>value}], or undef if none found

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
# @param    xmlpath     the XML path (See parseXMLPath)
# @return   an array ref of [[element,{val}]] where val can be a scalar or a subtree, or undef if none found
#
# See also getAttributes function for further details of the return type
#
sub getElements (@);
sub getElements (@) {
    my $self        = shift if ref($_[0]) eq $REF_NAME || undef;
    unless (@_ >= 1) { carp 'method getElements($$) requires one argument, and optionally a second argument.'; return undef; }
    # validate_pos( @_, 1, 0);
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

=item 2.  Or by calling the functions in an object oriented manor, as in:

    my $tppx = new XML::TreePP::XMLPath;
    $tppx->function1( args )

=back

Using either method works the same and returns the same output.

=head2 Method: charlexsplit

Here are three steps that can be used to parse values out of a string:

Step 1:

First, parse the entire string delimited by the / character.

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
key/val is delimited by the = character

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
which, when analyzed, will be collected as part of an element, but will not be
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

=head2 Method: filterXMLDoc

Filtering an XML Document, using an XMLPath, to find a node within the
document.

    #!/usr/bin/perl
    use XML::TreePP;
    use XML::TreePP::XMLPath qw(filterXMLDoc);
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
    # Parse the XML document.
    my $tpp = new XML::TreePP;
    my $xmldoc = $tpp->parse($xmldata);
    print "Output Test #1\n";
    dump( $xmldoc );
    #
    # Retrieve the sub tree of the XML document at path "level1/level2"
    my $xmlSubTree = filterXMLDoc($xmldoc, 'level1/level2');
    print "Output Test #2\n";
    dump( $xmlSubTree );
    #
    # Retrieve the sub tree of the XML document at path "level1/level2/level3[@attr1='val1']"
    my $xmlSubTree = filterXMLDoc($xmldoc, 'level1/level2/level3[@attr1="val1"]');
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

Validating attribute and value pairs of a given node.

    #!/usr/bin/perl
    use XML::TreePP;
    use XML::TreePP::XMLPath qw(filterXMLDoc);
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
    # Parse the XML document.
    my $tpp = new XML::TreePP;
    my $xmldoc = $tpp->parse($xmldata);
    print "Output Test #1\n";
    dump( $xmldoc );
    #
    # Retrieve the sub tree of the XML document at path "paragraph/sentence"
    my $xmlSubTree = filterXMLDoc($xmldoc, "paragraph/sentence");
    print "Output Test #2\n";
    dump( $xmlSubTree );
    #
    my (@params, $validatedSubTree);
    #
    # Test the XML Sub Tree to have an attribute "-language" with value "german"
    @params = (['-language', 'german']);
    $validatedSubTree = filterXMLDoc($xmlSubTree, [ ".", \@params ]);
    print "Output Test #3\n";
    dump( $validatedSubTree );
    #
    # Test the XML Sub Tree to have an attribute "-language" with value "english"
    @params = (['-language', 'english']);
    $validatedSubTree = filterXMLDoc($xmlSubTree, [ ".", \@params ]);
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

=head2 Method: validateAttrValue

    #!/usr/bin/perl
    use XML::TreePP;
    use XML::TreePP::XMLPath qw(getSubtree validateAttrValue);
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
    # Parse the XML document.
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
    # Parse the XML document.
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
    # Parse the XML document.
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
    # Parse the XML document.
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

C<XML::TreePP>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008 Center for the Application of Information Technologies.
All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

