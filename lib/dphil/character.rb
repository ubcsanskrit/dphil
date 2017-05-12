# frozen_string_literal: true

module Dphil
  #
  # Phylogenetic character for storing states and symbols.
  #
  class Character
    attr_reader :id, :states, :taxa_states, :frequency

    def initialize(id = nil, states = nil, **opts)
      @id = (opts[:id] || id)&.to_s.to_i
      @taxa_states = (opts[:states] || states)
                     .to_h.each_with_object({}) do |(taxon, state), acc|
        taxon = taxon.to_s if taxon.is_a?(Symbol)
        acc[taxon.to_i] = normalize_text(state)
      end

      unique_states = weighted_uniq(@taxa_states.values)
      if unique_states.count > SYMBOL_ARRAY.count
        raise ArgumentError,
              "Too many states (found #{unique_states.count}, " \
              "max #{SYMBOL_ARRAY.count})"
      end

      @states = {}
      @frequency = {}
      unique_states.each_with_index do |(state, frequency), index|
        symbol = SYMBOL_ARRAY[index]
        @states[symbol] = state
        @frequency[symbol] = frequency
      end
      instance_variables.each { |ivar| instance_variable_get(ivar).freeze }
    end

    # @return [Array] the list of taxa IDs.
    def taxa
      taxa_states.keys
    end

    # @param  symbol [String] a symbol associated with a character state
    # @return [String] the text state associated with the character state
    def state(symbol)
      states[symbol.to_s]
    end

    # @return [Hash] the Hash of symbols, keyed by text state
    def symbols
      @symbols ||= states.invert.freeze
    end

    # @param state [String] a text state associated with a character state
    # @return [String] the symbol associated with the character state
    def symbol(state)
      symbols[normalize_text(state)]
    end

    # @return [Hash] a Hash of symbols, keyed by taxa IDs.
    def taxa_symbols
      @taxa_symbols ||= (taxa_states.each_with_object({}) do |(taxon, state), acc|
        acc[taxon] = symbols[state]
      end).freeze
    end

    # @return [Hash] a Hash of taxa, keyed by text state.
    def states_taxa
      @states_taxa ||= (states.each_with_object({}) do |(_symbol, state), acc|
        acc[state] = taxa_states.select { |_taxon, tstate| state == tstate }.keys
      end).freeze
    end

    # @return [Hash] a Hash of taxa, keyed by symbol.
    def symbols_taxa
      @symbols_taxa ||= (states_taxa.each_with_object({}) do |(state, taxa), acc|
        acc[symbols[state]] = taxa
      end).freeze
    end

    def pretty_print(q)
      q.object_group(self) do
        q.breakable
        q.group(1) do
          q.text "@id=#{id}"
          q.breakable
          q.group(1, "{", "}") do
            q.seplist(states) do |symbol, state|
              q.text %(#{state.inspect}(#{symbol}) => #{states_taxa[state]})
            end
          end
        end
      end
    end

    def inspect
      pretty_inspect.chomp
    end
    alias to_s inspect

    private

    # @param text [String] an arbitrary string of text
    # @return [String] a Unicode-normalized, scrubbed, stripped, frozen copy
    def normalize_text(text)
      text = UNF::Normalizer.normalize(text.to_s, :nfc)
      text.scrub!
      text.strip!
      text.freeze
    end

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

    SYMBOL_ARRAY = IceNine.deep_freeze([*"A".."Z", *"a".."z"])
    private_constant :SYMBOL_ARRAY
  end
end
