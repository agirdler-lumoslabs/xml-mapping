#:invisible:
$:.unshift "../lib"
load "cleanup.rb"

require 'order'

require 'xml/xxpath_methods'

require 'test/unit/assertions'
include Test::Unit::Assertions  #<=
#:visible:
####read access
o=Order.load_from_file("order.xml") #<=
o.reference #<=
o.client #<=
o.items.keys #<=
o.items["RF-0034"].descr #<=
o.items["RF-0034"].total_price #<=
o.signatures #<=
o.signatures[2].name #<=
o.signatures[2].position #<=
## default value was set

o.total_price #<=

#:invisible:
assert_equal "12343-AHSHE-314159", o.reference
assert_equal "Jean Smith", o.client.name
assert_equal "San Francisco", o.client.work_address.city
assert_equal "San Mateo", o.client.home_address.city
assert_equal %w{RF-0001 RF-0034 RF-3341}, o.items.keys.sort
assert_equal ['John Doe','Jill Smith','Miles O\'Brien'], o.signatures.map{|s|s.name}
assert_equal 2575, (10 * o.total_price).round
#<=
#:visible:

####write access
o.client.name="James T. Kirk"
o.items['RF-4711'] = Item.new
o.items['RF-4711'].descr = 'power transfer grid'
o.items['RF-4711'].quantity = 2
o.items['RF-4711'].unit_price = 29.95

s=Signature.new
s.name='Harry Smith'
s.position='general manager'
o.signatures << s
xml=o.save_to_xml #convert to REXML node; there's also o.save_to_file(name) #<=
#:invisible_retval:
xml.write($stdout,2) #<=

#:invisible:
assert_equal %w{RF-0001 RF-0034 RF-3341 RF-4711}, xml.all_xpath("Item/@reference").map{|x|x.text}.sort
assert_equal ['John Doe','Jill Smith','Miles O\'Brien','Harry Smith'],
             xml.all_xpath("Signed-By/Signature/Name").map{|x|x.text}
#<=
#:visible:


#<=
#:visible_retval:
####Starting a new order from scratch
o = Order.new #<=
## attributes with default values (here: signatures) are set
## automatically

#:handle_exceptions:
xml=o.save_to_xml #<=
#:no_exceptions:
## can't save as long as there are still unset attributes without
## default values

o.reference = "FOOBAR-1234"

o.client = Client.new
o.client.name = 'Ford Prefect'
o.client.home_address = Address.new
o.client.home_address.street = '42 Park Av.'
o.client.home_address.city = 'small planet'
o.client.home_address.zip = 17263
o.client.home_address.state = 'Betelgeuse system'

o.items={'XY-42' => Item.new}
o.items['XY-42'].descr = 'improbability drive'
o.items['XY-42'].quantity = 3
o.items['XY-42'].unit_price = 299.95

#:invisible_retval:
xml=o.save_to_xml
xml.write($stdout,2)
#<=
#:invisible:
assert_equal "order", xml.name
assert_equal o.reference, xml.first_xpath("@reference").text
assert_equal o.client.name, xml.first_xpath("Client/Name").text
assert_equal o.client.home_address.street, xml.first_xpath("Client/Address[@where='home']/Street").text
assert_equal o.client.home_address.city, xml.first_xpath("Client/Address[@where='home']/City").text
assert_nil xml.first_xpath("Client/Address[@where='work']", :allow_nil=>true)
assert_equal 1, xml.all_xpath("Client/Address").size

o.client.work_address = Address.new
o.client.work_address.street = 'milky way 2'
o.client.work_address.city = 'Ursa Major'
o.client.work_address.zip = 18293
o.client.work_address.state = 'Magellan Cloud'
xml=o.save_to_xml

assert_equal o.client.work_address.street, xml.first_xpath("Client/Address[@where='work']/Street").text
assert_equal o.client.work_address.city, xml.first_xpath("Client/Address[@where='work']/City").text
assert_equal o.client.home_address.street, xml.first_xpath("Client/Address[@where='home']/Street").text
assert_equal 2, xml.all_xpath("Client/Address").size
#<=
#:visible:

## the root element name when saving an object to XML will by default
## be derived from the class name (in this example, "Order" became
## "order"). This can be overridden on a per-class basis; see
## XML::Mapping::ClassMethods#root_element_name for details.
