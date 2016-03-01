# frozen_string_literal: true
require "nyan_cat_formatter"
require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "dphil"
