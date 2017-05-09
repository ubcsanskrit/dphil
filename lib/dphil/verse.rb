# frozen_string_literal: true

module Dphil
  class Verse
    using ::Ragabash::Refinements
    attr_reader :ms, :id, :verse, :syllables, :weights, :identify

    def initialize(verse, ms: nil, id: nil)
      @verse = verse.to_str.safe_copy
      @ms = ms.safe_copy
      @id = id.safe_copy
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
