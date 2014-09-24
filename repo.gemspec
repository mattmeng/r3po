# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'r3po/constants'

Gem::Specification.new do |spec|
  spec.name          = "r3po"
  spec.version       = R3po::VERSION
  spec.authors       = ["Matt Meng"]
  spec.email         = ["mengmatt@gmail.com"]
  spec.summary       = %q{A gem that provides rake tasks to enforce standard semantic versioning and repo cleanliness.}
  spec.description   = %q{A gem that provides rake tasks to enforce standard semantic versioning and repo cleanliness.}
  spec.homepage      = "http://github.com/mattmeng/r3po"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "colorize", "~> 0"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
