# XML-XXPATH

## Overview, Motivation

Xml-xxpath is an (incomplete) XPath interpreter that is at the moment
bundled with xml-mapping. It is built on top of REXML. xml-mapping
uses xml-xxpath extensively for implementing its node types -- see the
README file and the reference documentation (and the source code) for
details. xml-xxpath, however, does not depend on xml-mapping at all,
and is useful in its own right -- maybe I'll later distribute it as a
seperate library instead of bundling it. For the time being, if you
want to use this XPath implementation stand-alone, you can just rip
the files <tt>lib/xml/xxpath.rb</tt>,
<tt>lib/xml/xxpath/steps.rb</tt>, and
<tt>lib/xml/xxpath_methods.rb</tt> out of the xml-mapping distribution
and use them on their own (they do not depend on anything else).

xml-xxpath's XPath support is vastly incomplete (see below), but, in
addition to the normal reading/matching functionality found in other
XPath implementations (i.e. "find all elements in a given XML document
matching a given XPath expression"), xml-xxpath supports <i>write
access</i>. For example, when writing the XPath expression
"/foo/bar[3]/baz[@key='hiho']" to the XML document

  <foo>
    <bar>
      <baz key='ab'>hello</baz>
      <baz key='xy'>goodbye</baz>
    </bar>
  </foo>

, you'll get:

  <foo>
    <bar>
      <baz key='ab'>hello</baz>
      <baz key='xy'>goodbye</baz>
    </bar>
    <bar/>
    <bar><baz key='hiho'/></bar>
  </foo>

This feature is used by xml-mapping when writing (marshalling) Ruby
objects to XML, and is actually the reason why I couldn't just use any
of the existing XPath implementations, e.g. the one that comes with
REXML. Also, the whole xml-xxpath implementation is just 300 lines of
Ruby code, it is quite fast (paths are precompiled), and xml-xxpath
returns matched elements in the order they appeared in the source
document -- I've heard REXML::XPath doesn't do that :)

Some basic knowledge of XPath is helpful for reading this document.

At the moment, xml-xxpath understands XPath expressions of the form
[<tt>/</tt>]_pathelement_<tt>/[/]</tt>_pathelement_<tt>/[/]</tt>...,
where each _pathelement_ must be one of these:

- a simple element name _name_, e.g. +signature+

- an attribute name, @_attr_name_, e.g. <tt>@key</tt>

- a combination of an element name and an attribute name and
  -value, in the form _elt_name_[@_attr_name_='_attr_value_']

- an element name and an index, _elt_name_[_index_]

- the "match-all" path element, <tt>*</tt>

- .

- name1|name2|...

- .[@key='xy'] / self::*[@key='xy']

- child::*[@key='xy']

- text()



Xml-xxpath only supports relative paths at this time, i.e. XPath
expressions beginning with "/" or "//" will still only find nodes
below the node the expression is applied to (as if you had written
"./" or ".//", respectively).


## Usage

Xml-xxpath defines the class XML::XXPath. An instance of that class
wraps an XPath expression, the string representation of which must be
supplied when constructing the instance. You then call instance
methods like _first_, _all_ or <i>create_new</i> on the instance,
supplying the REXML Element the XPath expression should be applied to,
and get the results, or, in the case of write access, the element is
updated in-place.


### Read Access

  :include: xpath_usage.intout

The objects supplied to the <tt>all()</tt>, <tt>first()</tt>, and
<tt>each()</tt> calls must be REXML element nodes, i.e. they must
support messages like <tt>elements</tt>, <tt>attributes</tt> etc
(instances of REXML::Element and its subclasses do this). The calls
return the found elements as instances of REXML::Element or
XML::XXPath::Accessors::Attribute. The latter is a wrapper around
attribute nodes that is largely call-compatible to
REXML::Element. This is so you can write things like
<tt>path.each{|node|puts node.text}</tt> without having to
special-case anything even if the path matches attributes, not just
elements.

As you can see, you can re-use path objects, applying them to
different XML elements at will. You should do this because the XPath
pattern is stored inside the XPath object in a pre-compiled form,
which makes it more efficient.

The path elements of the XPath pattern are applied to the
<tt>.elements</tt> collection of the passed XML element and its
sub-elements, starting with the first one. This is shown by the
following code:

  :include: xpath_docvsroot.intout

A REXML +Document+ object is a REXML +Element+ object whose +elements+
collection consists only of a single member -- the document's root
node. The first path element of the XPath -- "foo" in the example --
is matched against that. That is why the path "/bar" in the example
doesn't match anything when matched against the document +d+ itself.

An ordinary REXML +Element+ object that represents a node somewhere
inside an XML tree has an +elements+ collection that consists of all
the element's direct sub-elements. That is why XPath patterns matched
against the +firstelt+ element in the example *must not* start with
"/first" (unless there is a child node that is also named "first").


### Write Access

You may pass an <tt>:ensure_created=>true</tt> option argument to
_path_.first(_elt_)/_path_.all(_elt_) calls to make sure that _path_
exists inside the passed XML element _elt_. If it existed before,
nothing changes, and the call behaves just as it would without the
option argument. If the path didn't exist before, the XML element is
modified such that

- the path exists afterwards

- all paths that existed before still exist afterwards

- the modification is as small as possible (i.e. as few elements as
  possible are added, additional attributes are added to existing
  elements if possible etc.)

The created resp. previously existing, matching elements are returned.


Examples:

  :include: xpath_ensure_created.intout


Alternatively, you may pass a <tt>:create_new=>true</tt> option
argument or call <tt>create_new</tt> (_path_.create_new(_elt_) is
equivalent to _path_.first(_elt_,:create_new=>true)). In that case, a
new node is created in _elt_ for each path element of _path_ (or an
exception raised if that wasn't possible for any path element).

Examples:

  :include: xpath_create_new.intout

This feature is used in xml-mapping by node types like
XML::Mapping::ArrayNode, which must create a new instance of the
"per-array element path" for each element of the array to be stored in
an XML tree.


### Pathological Cases

What is created when the Path "*" is to be created inside an empty XML
element? The name of the element to be created isn't known, but still
some element must be created. The answer is that xml-xxpath creates a
special "unspecified" element whose name must be set by the caller
afterwards:

  :include: xpath_pathological.intout

The "newelt" object in the last example is an ordinary
REXML::Element. xml-xxpath mixes the "unspecified" attribute into that
class, as well as into the XML::XXPath::Accessors::Attribute class
mentioned above.


## Implentation notes

<tt>doc/xpath_impl_notes.txt</tt> contains some documentation on the
implementation of xml-xxpath.

## License

Ruby's.
