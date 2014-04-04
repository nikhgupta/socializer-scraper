# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'socializer/scraper/version'

Gem::Specification.new do |spec|
  spec.name          = "socializer-scraper"
  spec.version       = Socializer::Scraper::VERSION
  spec.authors       = ["Nikhil Gupta"]
  spec.email         = ["me@nikhgupta.com"]
  spec.description   = %q{Various scrapers for the Socializer application.}
  spec.summary       = %q{Various scrapers for the Socializer application.}
  spec.homepage      = "http://nikhgupta.com"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "yard"
  spec.add_development_dependency "guard-yard"

  spec.add_dependency "thor"
  spec.add_dependency "mongo"
  spec.add_dependency "anemone"
  spec.add_dependency "bson_ext"
end
