lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'rubeez/version'

spec = Gem::Specification.new do |s|
  s.name = "rubeez"
  s.version = Rubeez::VERSION
  s.platform = Gem::Platform::RUBY
  s.summary = "Rubeez"
  s.description = s.summary
  s.author = "Ryan Walker"
  s.email = "ryan.walker@rackspace.com"
  s.homepage = "http://github.com/ryandub/rubeez"

  s.add_dependency "mixlib-cli"
  s.add_dependency "mixlib-config"
  s.add_dependency "mixlib-log"
  s.add_dependency "fog"
  s.add_dependency "ruport"
  s.add_dependency "nokogiri"

  s.bindir = "bin"
  s.executables = %w(rubeez)

  s.require_path = 'lib'
  s.files = Dir.glob("{lib}/**/*")
end
