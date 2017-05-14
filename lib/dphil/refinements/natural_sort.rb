# frozen_string_literal: true

module Dphil
  module Refinements
    module NaturalSort
      refine Hash do
        def natural_sort_keys
          sort_by_key(true) do |a, b|
            NaturalSort.grouped_compare(a, b) || a <=> b
          end
        end

        def sort_by_key(recursive = false, &block)
          keys.sort(&block).each_with_object({}) do |key, acc|
            acc[key] = self[key]
            if recursive && acc[key].is_a?(Hash)
              acc[key] = acc[key].sort_by_key(true, &block)
            end
          end
        end
      end

      class << self
        CMP_REGEX = /((?:@{1,2}|[\$\:])?\p{L}+(?:[^\p{L}\d\s]*))|(\d+)/
        private_constant :CMP_REGEX

        def grouped_compare(a, b) # rubocop:disable CyclomaticComplexity
          a = a&.scan(CMP_REGEX)
          b = b&.scan(CMP_REGEX)
          return if a.blank? || b.blank?

          ret = nil
          [a.size, b.size].max.times do |index|
            a_cmp = coerce_chunk(a[index]) || (return -1)
            b_cmp = coerce_chunk(b[index]) || (return 1)
            ret = a_cmp <=> b_cmp || (a.is_a?(Integer) && -1 || b.is_a?(Integer) && 1)
            return ret unless ret == 0 # rubocop:disable NumericPredicate
          end
          ret
        end

        private

        def coerce_chunk(chunk)
          return if chunk.nil?
          return chunk[0] unless chunk[0].nil?
          Integer(chunk[1])
        end
      end
    end
  end
end
