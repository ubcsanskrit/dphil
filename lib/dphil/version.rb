# frozen_string_literal: true
module Dphil
  VERSION = "0.1.0"

  GEM_ROOT = Pathname.new(File.realpath(File.join(__dir__, "..", "..")))
  private_constant :GEM_ROOT
end
