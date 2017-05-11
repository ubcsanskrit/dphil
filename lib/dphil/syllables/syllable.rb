# frozen_string_literal: true

module Dphil
  class Syllables
    using ::Ragabash::Refinements
    class Syllable
      attr_reader :source, :weight, :parent, :index, :source_script

      def initialize(source, weight, **opts)
        @source = source.to_str.safe_copy.freeze
        @weight = weight.to_str.safe_copy.freeze
        @parent = opts[:parent]
        @index = opts[:index]&.to_i
        @source_script = opts[:source_script] || (@parent&.source_script)
        @slp1 = @source_script == :slp1 ? @source : opts[:slp1]&.to_str&.safe_copy.freeze
      end

      def inspect
        "[#{index}]#{source.inspect}(#{weight})"
      end

      def to_s
        @source.dup
      end

      def prev
        return unless @parent && @index && @index.positive?
        @parent[@index - 1]
      end

      def next
        return unless @parent && @index && @index < @parent.length
        @parent[@index + 1]
      end

      def simple_weight
        @simple_weight ||= weight.upcase.freeze
      end

      def slp1
        @slp1 ||= Transliterate.t(@source, @source_script, :slp1).freeze
      end
    end
  end
end
