# frozen_string_literal: true
require "forwardable"

require "dphil/syllables/syllable"

module Dphil
  class Syllables
    using ::Ragabash::Refinements
    include Enumerable
    extend Forwardable
    def_delegators :@syllables, :[], :each, :first, :last, :length

    attr_reader :source, :source_script, :weights, :syllables

    def initialize(source, source_script: nil)
      @source = source.to_str.safe_copy.freeze
      @source_script = source_script || Transliterate.detect(@source) || Transliterate.default_script
      slp1_syllables = VerseAnalysis.syllables(@source, from: @source_script, to: :slp1)
      @weights = VerseAnalysis.syllables_weights(slp1_syllables, from: :slp1, contextual: true).freeze
      @syllables = (slp1_syllables.map.with_index do |syl, i|
        source = @source_script == :slp1 ? syl : Transliterate.t(syl, :slp1, @source_script)
        Syllables::Syllable.new(source, @weights[i], parent: self, index: i, slp1: syl)
      end).freeze
    end

    def inspect
      "<Syllables \"#{@source}\":#{@source_script} (#{@weights}) (#{@syllables.count}) => #{@syllables.inspect}>"
    end

    def to_a
      @syllables.map { |syl| Transliterate.t(syl.source, :slp1, @source_script) }
    end

    def to_s
      @source.dup
    end

    def simple_weights
      @simple_weights ||= @weights.upcase.freeze
    end
  end
end
