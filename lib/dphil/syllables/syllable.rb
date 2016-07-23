# frozen_string_literal: true
module Dphil
  using ::Ragabash::Refinements
  class Syllables
    class Syllable
      attr_reader :str, :weight, :parent, :index

      def initialize(str, weight, parent = nil, index = nil)
        @str = str.to_str.safe_copy.freeze
        @weight = weight.to_str.safe_copy.freeze
        @parent = parent if parent
        @index = index.to_int if index
        freeze
      end

      def prev
        return unless @parent && @index && @index > 0
        @parent[@index - 1]
      end

      def next
        return unless @parent && @index && @index < @parent.length
        @parent[@index + 1]
      end

      def inspect
        "[#{index}]\"#{str}\"(#{weight})"
      end
    end
  end
end
