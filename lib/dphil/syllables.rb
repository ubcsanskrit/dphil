# frozen_string_literal: true
require "forwardable"

require "dphil/syllables/syllable"

module Dphil
  using ::Ragabash::Refinements
  class Syllables
    include Enumerable
    extend Forwardable
    def_delegators :@syllables, :[], :each, :first, :last, :length

    attr_reader :source, :source_script, :weights, :simple_weights, :syllables

    def initialize(source)
      @source = source.to_str.safe_copy
      @source_script = Transliterate.detect(@source) || Transliterate.default_script
      @raw_syllables = VerseAnalysis.syllables(@source, from: @source_script, to: :slp1)
      @weights = VerseAnalysis.syllables_weights(@raw_syllables, from: :slp1, contextual: true)
      @simple_weights = @weights.upcase
      @syllables = @raw_syllables.map.with_index do |syl, i|
        Syllables::Syllable.new(syl, @weights[i], self, i)
      end
      deep_freeze!
    end

    def inspect
      "#<Syllables \"#{@source}\" #{@syllables.inspect}>"
    end

    def to_a
      @raw_syllables.map { |syl| Transliterate.transliterate(syl, :slp1, @source_script) }
    end
  end
end
