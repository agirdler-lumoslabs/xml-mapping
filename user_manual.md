# XML-MAPPING: XML-to-object (and back) Mapper for Ruby, including XPath Interpreter

Xml-mapping is an easy to use, extensible library that allows you to
semi-automatically map Ruby objects to XML trees and vice versa.

## Download

For downloading the latest version, CVS repository access etc. go to:

http://rubyforge.org/projects/xml-mapping/

## Contents of this Document

- {Example}[aref:example]
- {Single-attribute Nodes}[aref:sanodes]
  - {Default Values}[aref:defaultvalues]
  - {Single-attribute Nodes with Sub-objects}[aref:subobjnodes]
  - {Attribute Handling Details, Augmenting Existing Classes}[aref:attrdefns]
- {Other Nodes}[aref:onodes]
  - {choice_node}[aref:choice_node]
  - {Readers/Writers}[aref:readerswriters]
- {Multiple Mappings per Class}[aref:mappings]
- {Defining your own Node Types}[aref:definingnodes]
- {XPath Interpreter}[aref:xpath]

## {Example}[a:example]

(example document stolen + extended from
http://www.castor.org/xml-mapping.html)

### Input Document:

  :include: order.xml

### Mapping Class Declaration:

  :include: order.rb

### Usage:

  :include: order_usage.intout

As shown in the example, you have to include XML::Mapping into a class
to turn it into a "mapping class". There are no other restrictions
imposed on mapping classes; you can add attributes and methods to
them, include additional modules in them, derive them from other
classes, derive other classes from them etc.pp.

An instance of a mapping class can be created from/converted into an
XML node with methods like XML::Mapping::ClassMethods.load_from_xml,
XML::Mapping#save_to_xml, XML::Mapping::ClassMethods.load_from_file,
XML::Mapping#save_to_file. Special class methods like "text_node",
"array_node" etc., called *node* *factory* *methods*, may be called
from the body of the class definition to define instance attributes
that are automatically and bidirectionally mapped to subtrees of the
XML element an instance of the class is mapped to.

## {Single-attribute Nodes}[a:sanodes]

For example, in the definition

  class Address
    include XML::Mapping

    text_node :city, "City"
    text_node :state, "State"
    numeric_node :zip, "ZIP"
    text_node :street, "Street"
  end

the first call to #text_node creates an attribute named "city" which
is mapped to the text of the XML child element defined by the XPath
expression "City" (xml-mapping includes an XPath interpreter that can
also be used seperately; see below[aref:xpath]). When you create an
instance of +Address+ from an XML element (using
Address.load_from_file(file_name) or
Address.load_from_xml(rexml_element)), that instance's "city"
attribute will be set to the text of the XML element's "City" child
element. When you convert an instance of +Address+ into an XML
element, a sub-element "City" is added and its text is set to the
current value of the +city+ attribute. The other node types
(numeric_node, array_node etc.) work analogously. Generally said, when
an instance of the above +Address+ class is created from or converted
to an XML tree, each of the four nodes in the class maps some parts of
that XML tree to a single, specific attribute of the +Adress+
instance. The name of that attribute is given in the first argument to
the node factory method. Such a node is called a "single-attribute
node". All node types that come with xml-mapping except one
(+choice_node+, which I'll talk about below) are single-attribute
nodes.


### {Default Values}[a:defaultvalues]

For each single-attribute node you may define a <i>default value</i>
which will be set if there was no value defined for the attribute in
the XML source.

From the example:

  class Signature
    include XML::Mapping

    text_node :position, "Position", :default_value=>"Some Employee"
  end

The semantics of default values are as follows:

- when creating a new instance from scratch:

  - attributes with default values are set to their default values

  - attributes without default values are left unset

  (when defining your own initializer, you'll have to call the
  inherited _initialize_ method in order to get this behaviour)

- when loading an instance from an XML document:

  - attributes without default values that are not represented in the
    XML raise an error

  - attributes with default values that are not represented in the XML
    are set to their default values

  - all other attributes are set to their respective values as present
    in the XML


- when saving an instance to an XML document:

  - unset attributes without default values raise an error

  - attributes with default values that are set to their default
    values are not saved

  - all other attributes are saved


This implies that:

- attributes that are set to their respective default values are not
  represented in the XML

- attributes without default values must be set explicitly before
  saving



### {Single-attribute Nodes with Sub-objects}[a:subobjnodes]

Single-attribute nodes of type +array_node+, +hash_node+, and
+object_node+ recursively map one or more subtrees of their XML to
sub-objects (e.g. array elements or hash values) of their
attribute. For example, with the line

  array_node :signatures, "Signed-By", "Signature", :class=>Signature, :default_value=>[]

, an attribute named "signatures" is added to the surrounding class
(here: +Order+); the attribute will be an array whose elements
correspond to the XML sub-trees yielded by the XPath expression
"Signed-By/Signature" (relative to the tree corresponding to the
+Order+ instance). Each element will be of class +Signature+
(internally, each element is created from its corresponding XML
subtree by just calling
<tt>Signature.load_from_xml(the_subtree)</tt>). The reason why the
path "Signed-By/Signature" is provided in two arguments instead of
just one combined one becomes apparent when marshalling the array
(along with the surrounding +Order+ object) back into a sequence of
XML elements. When that happens, "Signed-By" names the common base
element for all those elements, and "Signature" is the path that will
be duplicated for each element. For example, when the +signatures+
attribute contains an array with 3 +Signature+ instances (let's call
them <tt>sig1</tt>, <tt>sig2</tt>, and <tt>sig3</tt>) in it, it will
be marshalled to an XML tree that looks like this:

  <Signed-By>
    <Signature>
      [marshalled object sig1]
    </Signature>
    <Signature>
      [marshalled object sig2]
    </Signature>
    <Signature>
      [marshalled object sig3]
    </Signature>
  </Signed-By>

Internally, each +Signature+ instance is stored into its
<tt><Signature></tt> sub-element by calling
<tt>the_signature_instance.fill_into_xml(the_sub_element)</tt>. The
input document in the example above shows how this ends up looking.

<tt>hash_node</tt>s work similarly, but they define hash-valued attributes
instead of array-valued ones.

<tt>object_node</tt>s are the simplest of the three types of
single-attribute nodes with sub-objects. They just map a single given
subtree directly to their attribute value. See the example for
examples :)

The mentioned methods +load_from_xml+ and +fill_into_xml+ are the only
methods classes must implement in order to be usable in the
<tt>:class=></tt> keyword arguments to node factory methods. Mapping
classes (i.e. classes that <tt>include XML::Mapping</tt>)
automatically inherit those functions and can thus be readily used in
<tt>:class=></tt> arguments, as shown for the +Signature+ class in the
+array_node+ call above. In addition to that, xml-mapping adds those
methods to some of Ruby's core classes, namely +String+ and +Numeric+
(and thus +Float+, +Integer+, and +BigInt+). So you can also use
strings or numbers as sub-objects of attributes of +array_node+,
+hash_node+, or +object_node+ nodes. For example, say you have an XML
document like this one:

  :include: stringarray.xml

, and you want to map all the names to a string array attribute
+names+, you could do it like this:

  :include: stringarray.rb

usage:

  :include: stringarray_usage.intout

As a side node, this feature actually makes +text_node+ and
+numeric_node+ special cases of +object_node+. For example,
<tt>text_node :attr, "path"</tt> is the same as <tt>object_node :attr,
"path", :class=>String</tt>.


#### Polymorphic Sub-objects, Marshallers/Unmarshallers

Besides the <tt>:class</tt> keyword argument, there are alternative
ways for a single-attribute node with sub-objects to specify the way
the sub-objects are created from/marshalled into their subtrees.

First, it's possible not to specify anything at all -- in that case,
the class of a sub-object will be automatically deduced from the root
element name of its subtree. This allows you to achieve a kind of
"polymorphic", late-bound way to decide about the sub-object's
class. The following example document contains a hierarchical,
recursive set of named "documents" and "folders", where folders hold a
set of entries, each of which may again be either a document or a
folder:

  :include: documents_folders.xml

This can be mapped to Ruby like this:

  :include: documents_folders.rb

Usage:

  :include: documents_folders_usage.intout

As you see, the <tt>Folder#entries</tt> attribute is mapped via an
array_node that does not specify a <tt>:class</tt> or anything else to
govern the instantiation of the array's elements. This causes
xml-mapping to deduce the class of each array element from the root
element name of the corresponding XML tree. In this example, the root
element name is either "document" or "folder". The mapping between
root element names and class names is the one briefly described in
example[aref:example] at the beginning of this document -- the
unqualified class name is just converted to lower case and "dashed",
e.g. Foo::Bar::MyClass becomes "my-class"; and you may overwrite this
on a per-class basis by calling <tt>root_element_name
"the-new-name"</tt> in the class body. In our example, the root
element name "document" leads to an instantiation of class +Document+,
and the root element name "folder" leads to an instantiation of class
+Folder+.

Incidentally, the last example shows that you can readily derive
mapping classes from one another (as said before, you can also derive
mapping classes from other classes, include other modules into them
etc. at will). This works just like intuition thinks it should -- when
deriving one mapping class from another one, the list of nodes in
effect when loading/saving instances of the derived class will consist
of all nodes of that class and all superclasses, starting with the
topmost superclass that has nodes defined. There is one thing to take
care of though: When deriving mapping classes from one another, you
have to make sure to <tt>include XML::Mapping</tt> in each class. This
requirement exists purely due to ease-of-implementation
considerations; there are probably ways to do away with it, but the
inconvenience seemed not severe enough for me to bother (as
yet). Still, you might get "strange" errors if you forget to do it for
a class.

Besides the <tt>:class</tt> keyword argument and no argument, there is
a third way to specify the way the sub-objects are created
from/marshalled into their subtrees: <tt>:marshaller</tt> and/or
<tt>:unmarshaller</tt> keyword arguments. Here you pass procs in which
you just do all the work manually. So this is basically a "catch-all"
for cases where the other two alternatives are not appropriate for the
problem at hand. (*TODO*: Use other example?) Let's say we want to
extend the +Signature+ class from the initial example to include the
date on which the signature was created. We want the new XML
representation of such a signature to look like this:

  :include: time_node_w_marshallers.xml

So, a new "signed-on" element was added that holds the day, month, and
year. In the +Signature+ instance in Ruby, we want the date to be
stored in an attribute named +signed_on+ of type +Time+ (that's Ruby's
built-in +Time+ class).

One could think of using +object_node+, but something like
<tt>object_node :signed_on, "signed-on", :class=>Time</tt> won't work
because +Time+ isn't a mapping class and doesn't define methods
+load_from_xml+ and +fill_into_xml+ (we could easily define those
though; we'll talk about that possibility here[aref:attrdefns] and
here[aref:definingnodes]). The fastest, most ad-hoc way to achieve
what we want are :marshaller and :unmarshaller keyword arguments, like
this:

  :include: time_node_w_marshallers.intout

The <tt>:unmarshaller</tt> proc will be called whenever a +Signature+
instance is being read in from an XML source. The +xml+ argument
passed to the proc contains (as a REXML::Element instance) the XML
subtree corresponding to the node's attribute's sub-object currently
being read. In the case of our +object_node+, the sub-object is just
the node's attribute (+signed_on+) itself, and the subtree is the one
rooted at the <signed-on> element (if this were e.g. an +array_node+,
the <tt>:unmarshaller</tt> proc would be called once for each array
element, and +xml+ would hold the subtree corresponding to the
"current" array element). The proc is expected to extract the
sub-object's data from +xml+ and return the sub-object. So we have to
read the "year", "month", and "day" elements, construct a +Time+
instance from them and return that. One could just use the REXML API
to do that, but I've decided here to use the XPath interpreter that
comes with xml-mapping (xml/xxpath), and specifically the
'xml/xxpath_methods' utility library that adds methods like +first+ to
REMXML::Element. We call +first+ on +xml+ three times, passing XPath
expressions to extract the "year"/"month"/"day" sub-elements,
construct the +Time+ instance from that and return it. The XPath
library is explained in more detail below[aref:xpath].

The <tt>:marshaller</tt> proc will be called whenever a +Signature+
instance is being written into an XML tree. +xml+ is again the XML
subtree rooted at the <signed-on> element (it will still be empty when
this proc is called), and +value+ is the current value of the
sub-object (again, since this is an +object_node+, +value+ is the
node's attribute, i.e. the +Time+ instance). We have to fill +xml+
with the data from +value+ here. So we add three elements "year",
"month" and "day" and set their texts to the corresponding values from
+value+. The commented-out code shows an alternative implementation of
the same thing using the XPath interpreter.

It should be mentioned again that :marshaller/:unmarshaller procs are
possible with all single-attribute nodes with sub-objects, i.e. with
+object_node+, +array_node+, and +hash_node+. So, if you wanted to map
a whole array of date values, you could use +array_node+ with the same
:marshaller/:unmarshaller procs as above, for example:

  array_node :birthdays, "birthdays", "birthday",
             :unmarshaller=> <as above>,
             :marshaller=> <as above>

You can see that :marshaller/:unmarshaller procs give you more
flexibility, but they also impose more work because you essentially
have to do all the work of marshalling/unmarshalling the sub-objects
yourself. If you find yourself copying and pasting
marshaller/unmarshaller procs all over the place, you should instead
define your own node type or mix the marshalling/unmarshalling
capabilities into the +Time+ class itself. This is explained
here[aref:attrdefns] and here[aref:definingnodes], and you'll see that
it's not really much more work than writing :marshaller and
:unmarshaller procs (you essentially just move the code from those
procs into your own node type resp. into the +Time+ class), so you
should not hesitate to do this.

Another thing worth mentioning is that you don't have to specify
*both* a :marshaller and an :unmarshaller simultaneously. You can as
well give only one of them, and in addition to that pass a
<tt>:class</tt> argument or no argument. When you do that, the
specified marshaller (or unmarshaller) will be used when marshalling
(resp. unmarshalling) the sub-objects, and the other passed argument
(<tt>:class</tt> or none) will be employed when unmarshalling
(resp. marshalling) the sub-objects. So, in effect, you can deactivate
or "short-cut" some part of the marshalling/unmarshalling
functionality of a node type while retaining another part.



### {Attribute Handling Details, Augmenting Existing Classes}[a:attrdefns]

I'll shed some more light on how single-attribute nodes add mapped
attributes to Ruby classes. An attribute declaration like

  text_node :city, "City"

maps some portion of the XML tree (here: the "City" sub-element) to an
attribute (here: "city") of the class whose body the declaration
appears in. When writing (marshalling) instances of the surrounding
class into an XML document, xml-mapping will read the attribute value
from the instance using the function named +city+; when reading
(unmarshalling) an instance from an XML document, xml-mapping will use
the one-parameter function <tt>city=</tt> to set the attribute in the
instance to the value read from the XML document.

If these functions don't exist at the time the node declaration is
executed, xml-mapping adds default implementations that simply
read/write the attribute value to instance variables that have the
same name as the attribute. For example, the +city+ attribute
declaration in the +Address+ class in the example added functions
+city+ and <tt>city=</tt> that read/write from/to the instance
variable <tt>@city</tt>.

If, however, these functions already exist prior to defining the
attributes, xml-mapping will leave them untouched, so your precious
self-written accessor methods that do whatever complicated internal
processing of the data won't be overwritten.

This means that you can not only create new mapping classes from
scratch, you can also take existing classes that contain some
"business logic" and "augment" them with xml-mapping capabilities. As
a simple example, let's augment Ruby's "Time" class with node
declarations that declare XML mappings for the day, month etc. fields:

  :include: time_augm.intout

Here XML mappings are defined for the existing fields +year+, +month+
etc. Xml-mapping noticed that the getter methods for those attributes
existed, so it didn't overwrite them. When calling +save_to_xml+ on a
+Time+ object, these methods are called and return the object's values
for those fields, which then get written to the output XML.

So you can convert +Time+ objects into XML trees. What about reading
them back in from XML? All XML reading operations go through
<tt><Class>.load_from_xml</tt>. The +load_from_xml+ class method
inherited from XML::Mapping (see
XML::Mapping::ClassMethods#load_from_xml) allocates a new instance of
the class (+Time+), then calls +fill_from_xml+
(i.e. XML::Mapping#fill_from_xml) on it. +fill_from_xml+ iterates over
all our nodes in the order of their definition. For each node, its
data (the <year>, or <month>, or <day> etc. element) is read from the
XML source and then written to the +Time+ instance via the respective
setter method (<tt>year=</tt>, <tt>month=</tt>, <tt>day=</tt>
etc.). These methods didn't exist in +Time+ before (+Time+ objects are
immutable), so xml-mapping defined its own, default setter methods
that just set <tt>@year</tt>, <tt>@month</tt> etc. This is of course
pretty useless because +Time+ objects don't hold their time in these
variables, so the setter methods don't really change the time of the
+Time+ object. So we have to redefine +load_from_xml+ for the +Time+
class:

  :include: time_augm_loading.intout


## {Other Nodes}[a:onodes]

All nodes I've shown so far (node types text_node, numeric_node,
boolean_node, object_node, array_node, and hash_node) were
single-attribute nodes: The first parameter to the node factory method
of such a node is an attribute name, and the attribute of that name is
the only piece of the state of instances of the node's mapping class
that gets read/written by the node.

### {choice_node}[a:choice_node]

There is one node type distributed with xml-mapping that is not a
single-attribute node: +choice_node+. A +choice_node+ allows you to
specify a sequence of pairs, each consisting of an XPath expression
and another node (any node is supported here, including other
choice_nodes). When reading in an XML source, the choice_node will
delegate the work to the first node in the sequence whose
corresponding XPath expression was matched in the XML. When writing an
object back to XML, the choice_node will delegate the work to the
first node whose data was "present" in the object (for
single-attribute nodes, the data is considered "present" if the node's
attribute is non-nil; for choice_nodes, the data is considered
"present" if at least one of the node's sub-nodes is "present").

As a (somewhat contrived) example, here's a mapping for +Publication+
objects that have either a single author (contained in an "author" XML
attribute) or several "contributors" (contained in a sequence of
"contr" XML elements):

  :include: publication.intout

The symbols :if, :then, and :elsif (but not :else -- see below) in the
+choice_node+'s node factory method call are ignored; they may be
sprinkled across the argument list at will (preferably the way shown
above of course) to increase readability.

The rest of the arguments specify the mentioned sequence of XPath
expressions and corresponding nodes.

When reading a +Publication+ object from XML, the XPath expressions
from the +choice_node+ (<tt>@author</tt> and +contr+) will be matched
in sequence against the source XML tree until a match is found or the
end of the argument list is reached. If the end is reached, an
exception is raised. Otherwise, for the first XPath expression that
matched, the corresponding node will be invoked (i.e. used to read
actual data from the XML source into the +Person+ object). If you
specify :else, :default, or :otherwise in place of an XPath
expression, this is treated as an XPath expression that always
matches. So you can use :else (or :default or :otherwise) for a
"fallback" node that will be used if none of the other XPath
expressions matched (an example for this follows).

When writing a +Publication+ object back to XML, the first node in the
sequence whose data is "present" in the source object will be invoked
to write data from the object into the target XML tree (and the
corresponding XPath expression will be created in the XML tree if it
doesn't exist already). If there is no such node in the sequence, an
exception is raised. As said above, for single-attribute nodes, the
node's data is considered "present" if the node's attribute is
non-nil.  So, if you write a +Publication+ object to XML, and either
the +author+ or the +contributors+ attribute of the object is set, it
will be written; if both attributes are nil, an exception will be
raised.

A frequent use case for choice_nodes will probably be object
attributes that may be represented in multiple alternative ways in
XML. As an example, consider "Person" objects where the name of the
person should be stored alternatively in a sub-element named +name+,
or an attribute named +name+, or in the text of the +person+ element
itself. You can achieve this with +choice_node+ like this:

  :include: person.intout

Here all sub-nodes of the choice_nodes are single-attribute nodes
(text_nodes) with the same attribute (+name+). As you see, when
writing persons to XML, the name is always stored in a <name>
sub-element. Of course, this is because that alternative appears first
in the choice_node.


### {Readers/Writers}[a:readerswriters]

Finally, _all_ nodes support keyword arguments :reader and :writer
which allow you to extend or completely override the reading and/or
writing functionality of the node with your own code. The :reader as
well as the :writer argument must be a proc that takes as its
arguments the Ruby object to be read/written (instance of the mapping
class the node belongs to) and the XML tree to be written to/read
from. An optional third argument may be specified -- it will receive a
proc that wraps the default reader/writer functionality of the
node.

The :reader proc is for reading (from the XML into the object), the
:writer proc is for writing (from the object into the XML).

Here's a (really contrived) example:

  :include: reader.intout

So there's a "Foo" class with a text_node that would by default
(without the :reader and :writer proc) map the Ruby attribute "name"
to the XML attribute "name". The :reader proc is invoked when reading
from XML into a +Foo+ object. The +xml+ argument is the XML tree,
+obj+ is the object. +default_reader+ is the proc that wraps the
default reading functionality of the node. We invoke it at the
beginning. For this text_node, the default reading functionality is to
take the text of the "name" attribute of +xml+ and put it into the
+name+ attribute of +obj+. After that, we take the text of the "more"
attribute of +xml+ and append it to the +name+ attribute of +obj+. So
the XML tree <tt><foo name="Jim" more="XYZ"/></tt> is converted to a
+Foo+ object with +name+="JimXYZ".

In our :writer proc, we only take +obj+ (the +Foo+ object to be
written to XML) and +xml+ (the XML tree the stuff is to be written
to). Analogously to the :reader, we could take a proc that wraps the
default writing functionality of the node, but we don't do that
here--we completely override the writing functionality with our own
code, which just takes the +name+ attribute of the object and writes
"hi <the name> ho" to a +bar+ XML attribute in the XML tree (stupid
example, I know).

As a special convention, if you specify both a :reader and a :writer
for a node, and in both cases you do /not/ call the default behaviour,
then you should use the generic node type +node+, e.g.:

  class SomeClass
    include XML::Mapping

    ....

    node :reader=>proc{|obj,xml| ...},
         :writer=>proc{|obj,xml| ...}
  end

(since you're completely replacing both the reading and the writing
functionality, you're effectively replacing all the functionality of
the node, so it would be pointless and confusing to use one of the
more "specific" node types)

As you see, the purpose of readers and writers is to make it possible
to augment or override a node's functionality arbitrarily, so there
shouldn't be anything that's absolutely impossible to achieve with
xml-mapping. However, if you use readers and writers without invoking
the default behaviour, you really do everything manually, so you're
not doing any less work than you would do if you weren't using
xml-mapping at all. So you'll probably use readers and/or writers for
those bits of your mapping semantics that can't be achieved with
xml-mapping's predefined node types (an alternative approach might be
to override the +post_load+ and/or +post_save+ instance methods on the
mapping class -- see the reference documentation).

An advice similar to the one given above for marshallers/unmarshallers
applies here as well: If you find yourself writing lots of readers and
writers that only differ in some easily parameterizable aspects, you
should think about defining your own node types. We talk about that
below[aref:definingnodes], and it generally just means that you move
the (sensibly parameterized) code from your readers/writers to your
node types.


## {Multiple Mappings per Class}[a:mappings]

Sometimes you might want to represent the same Ruby object in multiple
alternative ways in XML. For example, the name of a "Person" object
could be represented either in a "name" element or a "name" attribute.

xml-mapping supports this by allowing you to define multiple disjoint
"mappings" for a mapping class. A mapping is by convention identified
with a symbol, e.g. <tt>:my_mapping</tt>, <tt>:other_mapping</tt>
etc., and each mapping comprises a root element name and a set of node
definitions. In the body of a mapping class definition, you switch to
another mapping with <tt>use_mapping :the_mapping</tt>. All following
node declarations will be added to that mapping *unless* you specify
the option :mapping=>:another_mapping for a node declaration (all node
types support that option). The default mapping (the mapping used if
there was no previous +use_mapping+ in the class body) is named
<tt>:_default</tt>.

All the worker methods like <tt>load_from_xml/file</tt>,
<tt>save_to_xml/file</tt>, <tt>load_object_from_xml/file</tt> support
a <tt>:mapping</tt> keyword argument to specify the mapping, which
again defaults to <tt>:_default</tt>.

In the following example, we define two mappings (the default one and
a mapping named <tt>:other</tt>) for +Person+ objects with a name, an
age and an address:

  :include: examples/person_mm.intout

In this example, each of the two mappings contains nodes that map the
same set of Ruby attributes (name, age and address). This is probably
what you want most of the time (since you're normally defining
multiple XML mappings for the same Ruby data), but it's not a
necessity at all. When a mapping class is defined, xml-mapping will
add all Ruby attributes from all mappings to it.

You may have noticed that the <tt>object_node</tt>s in the +Person+
class apply the mapping they were themselves defined in to their
sub-ordinated class (+Address+). This is the case for all
{Single-attribute Nodes with Sub-objects}[aref:subobjnodes]
(+object_node+, +array_node+ and +hash_node+) unless you explicitly
specify a different mapping for the sub-object(s) using the option
:sub_mapping, e.g.

  object_node :address, "address", :class=>Address, :sub_mapping=>:other



## {Defining your own Node Types}[a:definingnodes]

It's easy to write additional node types and register them with the
xml-mapping library (the following node types come with xml-mapping:
+node+, +text_node+, +numeric_node+, +boolean_node+, +object_node+,
+array_node+, +hash_node+, +choice_node+).

I'll first show an example, then some more theoretical insight.

### Example

Let's say we want to extend the +Signature+ class from the example to
include the time at which the signature was created. We want the new
XML representation of such a signature to look like this:

  :include: order_signature_enhanced.xml

(we only save year, month and day to make this example shorter), and
the mapping class declaration to look like this:

  :include: order_signature_enhanced.rb

(i.e. a new "time_node" declaration was added).

We want this +time_node+ call to define an attribute named +signed_on+
which holds the date value from the XML document in an instance of
class +Time+.

This node type can be defined with this piece of code:

  :include: time_node.rb

The last line registers the new node type with the xml-mapping
library. The name of the node factory method ("time_node") is
automatically derived from the class name of the node type
("TimeNode").

There will be one instance of the node type +TimeNode+ per +time_node+
declaration per mapping class (not per mapping class instance). That
instance (the "node" for short) will be created by the node factory
method (+time_node+); there's no need to instantiate the node type
directly. The +time_node+ method places the node into the mapping
class; the @owner attribute of the node is set to reference the
mapping class. The node factory method passes the mapping class the
node appears in (+Signature+), followed by its own arguments, to the
node's constructor. In the example, the +time_node+ method calls
<tt>TimeNode.new(Signature, :signed_on, "signed-on",
:default_value=>Time.now)</tt>). +new+ of course creates the node and
then delegates the arguments to our initializer +initialize+. We first
call the superclass's initializer, which strips off from the argument
list those arguments it handles itself, and returns the remaining
ones. In this case, the superclass XML::Mapping::SingleAttributeNode
handles the +Signature+, <tt>:signed_on</tt> and
<tt>:default_value=>Time.now</tt> arguments -- +Signature+ is stored
into <tt>@owner</tt>, <tt>:signed_on</tt> is stored into
<tt>@attrname</tt>, and <tt>{:default_value=>Time.now}</tt> is stored
into <tt>@options</tt>. The remaining argument list
<tt>["signed-on"]</tt> is returned; we capture the
<tt>"signed-on"</tt> string in _path_ (the rest of the argument list
(an empty array) we capture in _args_ for returning it at the end of
the initializer. This isn't strictly necessary, it's just a convention
that a node class initializer should always return those arguments it
didn't handle itself). We'll interpret _path_ as an XPath expression
that locates the time value relative to the parent mapping object's
XML tree (in this case, this would be the XML tree rooted at the
<tt><Signature></tt> element, i.e. the tree the +Signature+ instance
was read from). We'll later have to read/store the year, month, and
day values from <tt>path+"/year"</tt>, <tt>path+"/month"</tt>, and
<tt>path+"/day"</tt>, respectively, so we create (and precompile)
three corresponding XPath expressions using XML::XXPath.new and store
them into member variables of the node. XML::XXPath is an XPath
implementation that is bundled with xml-mapping. It is very
incomplete, but it supports writing (not just reading) of XML nodes,
which is needed to support writing data back to XML. The XML::XXPath
library is explained in more detail below[aref:xpath].

The +extract_attr_value+ method is called whenever an instance of the
mapping class the node belongs to (+Signature+ in the example) is
being created from an XML tree. The parameter _xml_ is that tree
(again, this is the tree rooted at the <tt><Signature></tt> element in
this example). The method implementation is expected to extract the
single attribute's value from _xml_ and return it, or raise
XML::Mapping::SingleAttributeNode::NoAttrValueSet if the attribute was
"unset" in the XML (this exception tells the framework that the
default value should be put in place if it was defined), or raise any
other exception to signal an error and abort the whole process. Our
superclass XML::Mapping::SingleAttributeNode will store the returned
single attribute's value into the <tt>signed_on</tt> attribute of the
+Signature+ instance being read in. In our implementation, we apply
the xpath expressions created during initialization to _xml_
(e.g. <tt>@y_path.first(xml)</tt>). An expression
_xpath_expr_.first(_xml_) returns (as a REXML element) the first
sub-element of _xml_ that matches _xpath_expr_, or raises
XML::XXPathError if there was no such element. We apply REXML's _text_
method to the returned element to get out the element's text, convert
it to integer, and supply it to the constructor of the +Time+ object
to be returned. As a side note, if an XPath expression matches XML
attributes, XML::XXPath methods like _first_ will return
XML::XXPath::Accessors::Attribute nodes that behave similarly to
REXML::Element nodes, including support for messages like _name_ and
_text_, so this would've worked also if our XPath expressions had
referred to XML attributes, not elements. The +default_when_xpath_err+
thing calls the supplied block and returns its value, but maps the
exception XML::XXPathError to the mentioned
XML::Mapping::SingleAttributeNode::NoAttrValueSet (any other
exceptions fall through unchanged). As said above,
XML::Mapping::SingleAttributeNode::NoAttrValueSet is caught by the
framework (more precisely, by our superclass
XML::Mapping::SingleAttributeNode), and the default value is set if it
was provided. So you should just wrap +default_when_xpath_err+ around
any applications of XPath expressions whose non-presence in the XML
you want to be considered a non-presence of the attribute you're
trying to extract. (XML::XXPath is designed to know knothing about
XML::Mapping, so it doesn't raise
XML::Mapping::SingleAttributeNode::NoAttrValueSet directly)

The +set_attr_value+ method is called whenever an instance of the
mapping class the node belongs to (+Signature+ in the example) is
being stored into an XML tree. The _xml_ parameter is the XML tree (a
REXML element node; here this is again the tree rooted at the
<tt><Signature></tt> element); _value_ is the current value of the
single attribute (in this example, the <tt>signed_on</tt> attribute of
the +Signature+ instance being stored). _xml_ will most probably be
"half-populated" by the time this method is called -- the framework
calls the +set_attr_value+ methods of all nodes of a mapping class in
the order of their definition, letting each node fill its "bit" into
_xml_. The method implementation is expected to write _value_ into
(the correct sub-elements of) _xml_, or raise an exception to signal
an error and abort the whole process. No default value handling is
done here; +set_attr_value+ won't be called at all if the attribute
had been set to its default value. In our implementation we grab the
year, month and day values from _value_ (which must be a +Time+), and
store it into the sub-elements of _xml_ identified by XPath
expressions <tt>@y_path</tt>, <tt>@m_path</tt> and <tt>@d_path</tt>,
respectively. We do this by calling XML::XXPath#first with an
additional parameter <tt>:ensure_created=>true</tt>. An expression
_xpath_expr_.first(_xml_,:ensure_created=>true) works just like
_xpath_expr_.first(_xml_) if _xpath_expr_ was already present in
_xml_. If it was not, it is created (preferably at the end of _xml_'s
list of sub-nodes), and returned. See below[aref:xpath] for a more
detailed documentation of the XPath interpreter.

### Element order in created XML documents

As just said, XML::XXPath, when used to create new XML nodes,
generally appends those nodes to the end of the list of subnodes of
the node the xpath expression was applied to. All xml-mapping nodes
that come with xml-mapping use XML::XXPath when writing data to XML,
and therefore also append their data to the XML data written by
preceding nodes (the nodes are invoked in the order of their
definition). This means that, generally, your output data will appear
in the XML document in the same order in which the corresponding
xml-mapping node definitions appeared in the mapping class (unless you
used XPath expressions like foo[number] which explicitly dictate a
fixed position in the sequence of XML nodes). For instance, in the
+Order+ class from the example at the beginning of this document, if
we put the <tt>:signatures</tt> node _before_ the <tt>:items</tt>
node, the <tt><Signed-By></tt> element will appear _before_ the
sequence of <tt><Item></tt> elements in the output XML.


The following is a more systematic overview of the basic node
types. The description is self-contained, so some information from the
previous section will be repeated.

### Node Types Are Ruby Classes

A node type is implemented as a Ruby class derived from
XML::Mapping::Node or one of its subclasses.

The following node types (node classes) come with xml-mapping (they
all live in the XML::Mapping namespace, which I've left out here for
brevity):

  Node
   +-SingleAttributeNode
   |  +-SubObjectBaseNode
   |  |  +-ObjectNode
   |  |  +-ArrayNode
   |  |  +-HashNode
   |  +-TextNode
   |  +-NumericNode
   |  +-BooleanNode
   +-ChoiceNode

XML::Mapping::Node is the base class for all nodes,
XML::Mapping::SingleAttributeNode is the base class for
{single-attribute nodes}[aref:sanodes], and
XML::Mapping::SubObjectBaseNode is the base class for
{single-attribute nodes with
sub-objects}[aref:subobjnodes]. XML::Mapping::TextNode,
XML::Mapping::ArrayNode etc. are of course the +text_node+,
+array_node+ etc. we've talked about in this document. When you've
written a new node class, you register it with xml-mapping by calling
<tt>XML::Mapping.add_node_class MyNode</tt>. When you do that,
xml-mapping automatically defines the node factory method for your
class -- the method's name (e.g. +my_node+) is derived from the node's
class name (e.g. Foo::Bar::MyNode) by stripping all parent module
names, and then converting capital letters to lowercase and preceding
them with an underscore. In fact, this is just how all the predefined
node types are defined -- those node types are not "special"; they're
defined in the source file +xml/mapping/standard_nodes.rb+ and then
registered normally in +xml/mapping.rb+. The source code of the
built-in nodes is not very long or complicated; you may consider
reading it in addition to this text to gain a better understanding.


### How Node Types Work

The xml-mapping core "operates" node types as follows:


#### Node Initialization

As said above, when a node class is registered with xml-mapping by
calling <tt>XML::Mapping.add_node_class TheNodeClass</tt>, xml-mapping
automatically generates the node factory method for that type. The
node factory method will effectively be defined as a class method of
the XML::Mapping module, which is why one can call it from the body of
a mapping class definition. The generated method will create a new
instance of the node class (a *node* for short) by calling _new_ on
the node class. The list of parameters to _new_ will consist of <i>the
mapping class, followed by all arguments that were passed to the node
factory method</i>. For example, when you have this node declaration:

  class MyMappingClass
    include XML::Mapping

    my_node :foo, "bar", 42, :hi=>"ho"
  end

, then the node factory method (+my_node+) calls
<tt>MyNode.new(MyMappingClass, :foo, "bar", 42, :hi=>"ho")</tt>.

_new_ of course creates the instance and calls _initialize_ on it. The
_initialize_ implementation will generally store the parameters into
some instance variables for later usage. As a convention, _initialize_
should always extract from the parameter list those parameters it
processes itself, process them, and return an array containing the
remaining (still unprocessed) parameters. Thus, an implementation of
_initialize_ follows this pattern:

  def initialize(*args)
    myparam1,myparam2,...,myparamx,*args = super(*args)

    .... process the myparam1,myparam2,...,myparamx ....

    # return still unprocessed args
    args
  end

(since the called superclass initializer is written the same way, the
parameter array returned by it will already be stripped of all
parameters that the superclass initializer (or any of its
superclasses's initializers) processed)

This technique is a simple way to "chain" the initializers of all
superclasses of a node class, starting with the topmost one (Node), so
that each initializer can easily find out and process the parameters
it is responsible for.

The base node class XML::Mapping::Node provides an _initialize_
implementation that, among other things (described below), adds _self_
(i.e. the created node) to the internal list of nodes held by the
mapping class, and sets the @owner attribute of _self_ to reference
the mapping class.

So, effectively there will be one instance of a node class (a node)
per node definition, and that instance lives in the mapping class the
node was defined in.


#### Node Operation during Marshalling and Unmarshalling

When an instance of a mapping class is created or filled from an XML
tree, xml-mapping will call +xml_to_obj+ on all nodes defined in that
mapping class in the {mapping}[aref:mappings] the node is defined in,
in the order of their definition. Two parameters will be passed: the
mapping class instance being created/filled, and the XML tree the
instance is being created/filled from. The implementation of
+xml_to_obj+ is expected to read whatever pieces of data it is
responsible for from the XML tree and put it into the appropriate
variables/attributes etc. of the instance.

When an instance of a mapping class is stored or filled into an XML
tree, xml-mapping will call +obj_to_xml+ on all nodes defined in that
mapping class in the {mapping}[aref:mappings] the node is defined in,
in the order of their definition, again passing as parameters the
mapping class instance being stored, and the XML tree the instance is
being stored/filled into. The implementation of +obj_to_xml+ is
expected to read whatever pieces of data it is responsible for from
the instance and put it into the appropriate XML elements/XML attr
etc. of the XML tree.


### Basic Node Types Overview

The following is an overview of how initialization and
marshalling/unmarshalling is implemented in the node base classes
(Node, SingleAttributeNode, and SubObjectBaseNode).

TODO: summary table: member var name; introduced in class; meaning

#### Node

In _initialize_, the mapping class and the option arguments are
stripped from the argument list. The mapping class is stored in
@owner, the option arguments are stored (as a hash) in @options (the
hash will be empty if no options were given). The
{mapping}[aref:mappings] the node is defined in is determined
(:mapping option, last <tt>use_mapping</tt> or <tt>:_default</tt>) and
stored in @mapping. The node then stores itself in the list of nodes
of the mapping class belonging to the mapping
(<tt>@owner.xml_mapping_nodes(:mapping=>@mapping)</tt>; see
XML::Mapping::ClassMethods#xml_mapping_nodes). This list is the list
of nodes later used when marshalling/unmarshalling an instance of the
mapping class with respect to a given mapping. This means that node
implementors will not normally "see" anything of the mapping (they
don't need to access the @mapping variable) because the
marshalling/unmarshalling methods
(<tt>obj_to_xml</tt>/<tt>xml_to_obj</tt>) simply won't be called if
the node's mapping is not the same as the mapping the
marshalling/unmarshalling is happening with.

Furthermore, if :reader and/or :writer options were given,
<tt>xml_to_obj</tt> resp. <tt>obj_to_xml</tt> are transparently
overwritten on the node to delegate to the supplied :reader/:writer
procs.

The marshalling/unmarshalling methods
(<tt>obj_to_xml</tt>/<tt>xml_to_obj</tt>) are not implemented in
+Node+ (they just raise an exception).


#### SingleAttributeNode

In _initialize_, the attribute name is stripped from the argument list
and stored in @attrname, and an attribute of that name is added to the
mapping class the node belongs to.

During marshalling/unmarshalling of an object to/from XML,
single-attribute nodes only read/write a single piece of the object's
state: the single attribute (@attrname) the node handles. Because of
this, the <tt>obj_to_xml</tt>/<tt>xml_to_obj</tt> implementations in
SingleAttributeNode call two new methods introduced by
SingleAttributeNode, which must be overwritten by subclasses:

  extract_attr_value(xml)

  set_attr_value(xml, value)

<tt>extract_attr_value(xml)</tt> is called by <tt>xml_to_obj</tt>
during unmarshalling. _xml_ is the XML tree being read. The method
must read the attribute's value from _xml_ and return
it. <tt>xml_to_obj</tt> will set the attribute to that value.

<tt>set_attr_value(xml, value)</tt> is called by <tt>obj_to_xml</tt>
during marshalling. _xml_ is the XML tree being written, _value_ is
the current value of the attribute. The method must write _value_ into
(the correct sub-elements/attributes) of _xml_.

SingleAttributeNode also handles the default value, if it was
specified (via the :default_value option): When writing data to XML,
<tt>set_attr_value(xml, value)</tt> won't be called if the attribute
was set to the default value. When reading data from XML, the
<tt>extract_attr_value(xml)</tt> implementation must raise a special
exception, XML::Mapping::SingleAttributeNode::NoAttrValueSet, if it
wants to indicate that the data was not present in the
XML. SingleAttributeNode will catch this exception and put the default
value, if it was defined, into the attribute.


#### SubObjectBaseNode

The initializer will set up additional member variables @sub_mapping,
@marshaller, and @unmarshaller.

@sub_mapping contains the mapping to be used when reading/writing the
sub-objects (either specified with :sub_mapping, or, by default, the
mapping the node itself was defined in).

@marshaller and @unmarshaller contain procs that encapsulate
writing/reading of sub-objects to/from XML, as specified by the user
with :class/:marshaller/:unmarshaller etc. options (the meaning of
those different options was described {above}[aref:subobjnodes]). The
procs are there to be called from <tt>extract_attr_value</tt> or
<tt>set_attr_value</tt> whenever the need arises.


## {XPath Interpreter}[a:xpath]

XML::XXPath is an XPath parser. It is used in xml-mapping node type
definitions, but can just as well be utilized stand-alone (it does not
depend on xml-mapping). XML::XXPath is very incomplete and probably
will always be, but it should be reasonably efficient (XPath
expressions are precompiled), and, most importantly, it supports write
access, which is needed for writing objects to XML. For example, if
you create the path "/foo/bar[3]/baz[@key='hiho']" in the XML document

  <foo>
    <bar>
      <baz key="ab">hello</baz>
      <baz key="xy">goodbye</baz>
    </bar>
  </foo>

, you'll get:

  <foo>
    <bar>
      <baz key='ab'>hello</baz>
      <baz key='xy'>goodbye</baz>
    </bar>
    <bar/>
    <bar>
      <baz key='hiho'/>
    </bar>
  </foo>

XML::XXPath is explained in more detail in the reference documentation
and the user_manual_xxpath file.


## License

Ruby's.
