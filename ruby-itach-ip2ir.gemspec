# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ruby-itach-ip2ir/version'

Gem::Specification.new do |spec|
  spec.name          = "ruby-itach-ip2ir"
  spec.version       = RubyItachIp2ir::VERSION
  spec.authors       = ["Luke Mcildoon"]
  spec.email         = ["luke@twofiftyfive.net"]
  spec.description   = %q{Unofficial - Ruby interface to Global Cache's itach ip2ir infrared emitter devices}
  spec.summary       = %q{TODO: Write a gem summary}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
