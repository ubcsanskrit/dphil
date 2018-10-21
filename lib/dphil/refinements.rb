# frozen_string_literal: true

require "ice_nine"
require "dphil/refinements/enhanced_array"
require "dphil/refinements/natural_sort"

module Dphil
  module Refinements
    refine Object do
      def try_dup
        respond_to?(:dup) ? dup : self
      end

      def deep_freeze
        ::IceNine.deep_freeze(self)
      end

      def safe_copy
        ::IceNine.deep_freeze(try_dup)
      end
    end

    refine String do
      def safe_copy
        frozen? ? self : dup.freeze
      end
    end

    refine NilClass do
      def safe_copy
        nil
      end
    end
  end
end
