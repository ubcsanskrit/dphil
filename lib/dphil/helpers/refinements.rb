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

        alias_method :deep_dup, :try_dup
        alias_method :safe_copy, :try_dup
      end

      refine NilClass do
        def try_dup
          self
        end

        alias_method :deep_dup, :try_dup
        alias_method :safe_copy, :try_dup
      end

      refine FalseClass do
        def try_dup
          self
        end

        alias_method :deep_dup, :try_dup
        alias_method :safe_copy, :try_dup
      end

      refine TrueClass do
        def try_dup
          self
        end

        alias_method :deep_dup, :try_dup
        alias_method :safe_copy, :try_dup
      end

      refine Symbol do
        def try_dup
          self
        end

        alias_method :deep_dup, :try_dup
        alias_method :safe_copy, :try_dup
      end

      refine Numeric do
        def try_dup
          self
        end

        alias_method :deep_dup, :try_dup
        alias_method :safe_copy, :try_dup
      end

      # Necessary to re-override Numeric
      require "bigdecimal"
      refine BigDecimal do
        def try_dup
          dup
        end

        alias_method :deep_dup, :try_dup

        def safe_copy
          frozen? ? self : dup
        end
      end

      refine String do
        def safe_copy
          frozen? ? self : dup
        end
      end

      refine Array do
        def deep_dup
          map { |value| value.deep_dup } # rubocop:disable Style/SymbolProc
        end
      end

      refine Hash do
        def deep_dup
          hash = dup
          each_pair do |key, value|
            if ::String === key # rubocop:disable Style/CaseEquality
              hash[key] = value.deep_dup
            else
              hash.delete(key)
              hash[key.deep_dup] = value.deep_dup
            end
          end
          hash
        end
      end

      refine Set do
        def deep_dup
          set_a = to_a
          set_a.map! do |val|
            next val if ::String === val # rubocop:disable Style/CaseEquality
            val.deep_dup
          end
          self.class[set_a]
        end
      end
    end
  end
end
