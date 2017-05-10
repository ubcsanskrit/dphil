# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "dphil/version"

Gem::Specification.new do |spec| # rubocop:disable BlockLength
  spec.name          = "dphil"
  spec.version       = Dphil::VERSION
  spec.authors       = ["Tim Bellefleur"]
  spec.email         = ["nomoon@phoebus.ca"]

  spec.summary       = "UBC Sanskrit Digital Philology Gem (all-in-one)"
  spec.homepage      = "https://github.com/ubcsanskrit/dphil"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^spec/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = "~> 2.4"

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "rspec", "~> 3.5"
  spec.add_development_dependency "rubocop", "~> 0.41"
  spec.add_development_dependency "rubocop-rspec", "~> 1.5"
  spec.add_development_dependency "pry", "~> 0.10.3"
  spec.add_development_dependency "pry-byebug", "~> 3.4"
  spec.add_development_dependency "yard", "~> 0.9"

  spec.add_runtime_dependency "ragabash", "~> 0.3"
  spec.add_runtime_dependency "awesome_print", "~> 1.7"
  spec.add_runtime_dependency "activesupport", "~> 5.1"
  spec.add_runtime_dependency "nokogiri", "~> 1.6"
  spec.add_runtime_dependency "psych", "~> 2.0"
  spec.add_runtime_dependency "hashie", "~> 3.0"
  spec.add_runtime_dependency "amatch", "~> 0.3"
  spec.add_runtime_dependency "sanscript", "~> 0.8"
  spec.add_runtime_dependency "oj", "~> 3.0"
  spec.add_runtime_dependency "neatjson", "~> 0.8"
  spec.add_runtime_dependency "json-ld", "~> 2.1"
end
