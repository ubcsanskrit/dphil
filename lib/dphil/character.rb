# frozen_string_literal: true

module Dphil
  #
  # Phylogenetic character for storing states and symbols.
  #
  # Immutable.
  #
  class Character
    attr_reader :id

    def initialize(opts = {})
      @id = opts[:id]&.to_i

      unique_states = weighted_uniq(opts[:states].to_a)
      if unique_states.count > SYMBOL_ARRAY.count
        raise ArgumentError,
              "Too many states (found #{unique_states.count}, " \
              "max #{SYMBOL_ARRAY.count})"
      end

      @states = unique_states.each_with_object({})
                             .with_index do |(state, acc), index|
        acc[state.first&.dup.freeze] = SYMBOL_ARRAY[index]
      end
      @symbols = @states.invert

      IceNine.deep_freeze(self)
    end

    def states(key = nil)
      key.nil? ? @states : @states[key]
    end

    def symbols(key = nil)
      key.nil? ? @symbols : @symbols[key]
    end

    private

    def weighted_uniq(array)
      weighted_hash = array.each_with_object({}) do |v, acc|
        acc[v] ||= 0
        acc[v] += 1
      end

      n = 0
      weighted_hash = weighted_hash.sort_by do |x|
        n += 1
        [-x[1], n]
      end
      weighted_hash.to_h
    end

    SYMBOL_ARRAY = IceNine.deep_freeze([*"A".."Z", *"a".."z", *"0".."9"])
    private_constant :SYMBOL_ARRAY
  end
end
