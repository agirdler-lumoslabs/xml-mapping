$:.push File.expand_path('../lib', __FILE__)
require 'xml/mapping/version'

FILE_RDOC_MAIN = 'user_manual.md'.freeze
FILES_RDOC_EXTRA = [FILE_RDOC_MAIN] + %w{README.md user_manual_xxpath.md TODO.txt doc/xpath_impl_notes.txt}
FILES_RDOC_INCLUDES = `git ls-files examples`.split("\n").map{|f| f.gsub(/.intin.rb$/, '.intout')}

Gem::Specification.new do |config|
  config.name = 'xml-mapping'
  config.version = XML::Mapping::VERSION
  config.authors = ['Olaf Klischat']
  config.email = 'olaf.klischat@gmail.com'
  config.homepage = 'https://github.com/multi-io/xml-mapping'
  config.summary = 'XML-Object mapper for Ruby'
  config.description = 'An easy to use, extensible library for semi-automatically mapping Ruby objects to XML and back. Includes an XPath interpreter.'

  config.rubyforge_project = 'xml-mapping'
  config.platform = Gem::Platform::RUBY
  config.licenses = ['Apache-2.0']


  config.files += FILES_RDOC_EXTRA
  config.files += FILES_RDOC_INCLUDES
  config.files += `git ls-files lib test`.split("\n")
  config.files += %w{LICENSE Rakefile}
  config.test_file = 'test/all_tests.rb'
  config.require_path = 'lib'
  config.extra_rdoc_files = FILES_RDOC_EXTRA
  config.rdoc_options += %w{--include examples}

  config.add_development_dependency 'rake', '~> 0'
end
