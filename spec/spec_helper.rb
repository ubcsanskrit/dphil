# frozen_string_literal: true

require "simplecov"
require "coveralls"
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new [
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter,
]
SimpleCov.start do
  add_filter "/spec/"
end

ENV["RUBY_ENV"] = "test" # for logger debug purposes

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "dphil"

RSpec::Matchers.define_negated_matcher :not_be_empty, :be_empty
RSpec::Matchers.define_negated_matcher :not_be_zero, :be_zero
