# frozen_string_literal: true
require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "dphil"

RSpec::Matchers.define_negated_matcher :not_be_empty, :be_empty
RSpec::Matchers.define_negated_matcher :not_be_zero, :be_zero
