# frozen_string_literal: true

require "amatch"

module Dphil
  module Compare
    @control_match = /\{\{.*\}\}/

    def self.compare_words(a, b)
      return (a == b ? 1.0 : 0.0) if @control_match.match(a) || @control_match.match(b)
      [
        Amatch::PairDistance.new(a).similar(b),
        Amatch::LongestSubsequence.new(a).similar(b),
        Amatch::JaroWinkler.new(a).similar(b),
      ].max
    end
  end
end
