# frozen_string_literal: true
require "ice_nine"

module Dphil
  module Helpers
    module Refinements
      refine Object do
        def deep_freeze
          IceNine.deep_freeze(self)
        end

        def deep_freeze!
          IceNine.deep_freeze!(self)
        end

        def try_first
          respond_to?(:first) ? first : self
        end

        def try_dup
          dup
        rescue TypeError
          self
        end

        def deep_dup
          dup
        rescue TypeError
          self
        end
      end

      class NilClass
        def try_dup
          self
        end

        def deep_dup
          self
        end
      end

      class FalseClass
        def try_dup
          self
        end

        def deep_dup
          self
        end
      end

      class TrueClass
        def try_dup
          self
        end

        def deep_dup
          self
        end
      end

      class Symbol
        def try_dup
          self
        end

        def deep_dup
          self
        end
      end

      class Numeric
        def try_dup
          self
        end

        def deep_dup
          self
        end
      end

      # Necessary to re-override Numeric
      class BigDecimal
        def try_dup
          dup
        end

        def deep_dup
          dup
        end
      end

      class Array
        def deep_dup
          map(&:deep_dup)
        end
      end

      class Hash
        def deep_dup
          hash = dup
          each_pair do |key, value|
            if key.frozen? && ::String === key # rubocop:disable Style/CaseEquality
              hash[key] = value.deep_dup
            else
              hash.delete(key)
              hash[key.deep_dup] = value.deep_dup
            end
          end
          hash
        end
      end

      class Set
        def deep_dup
          set_a = to_a
          set_a.map! do |val|
            next val if val.frozen? && ::String === val # rubocop:disable Style/CaseEquality
            val.deep_dup
          end
          self.class[set_a]
        end
      end
    end
  end
end
