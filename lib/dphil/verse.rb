# frozen_string_literal: true
module Dphil
  class Verse
    attr_reader :ms, :id, :verse, :syllables, :weights, :identify

    def initialize(verse, ms: nil, id: nil)
      unless verse.respond_to?(:to_str)
        raise ArgumentError, "first argument must be have a String representation"
      end
      @ms = ms.dup rescue ms # rubocop:disable Style/RescueModifier
      @id = id.dup rescue id # rubocop:disable Style/RescueModifier
      @identify = VerseAnalysis.identify(@verse)
      deep_freeze
    end

    def to_json(options)
      { ms: ms,
        id: id,
        verse: verse,
        syllables: syllables,
        weights: weights,
        identify: identify }.to_json(options)
    end
  end
end
