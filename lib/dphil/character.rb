# frozen_string_literal: true

module Dphil
  #
  # Phylogenetic character for storing states and symbols.
  #
  # Immutable.
  #
  class Character
    # Instantiates a new Character.
    # @overload initialize(id = nil, states = nil)
    #   @param id [Integer] a Character ID
    #   @param states [Hash] a Hash of `taxon_ID => text_state`
    # @overload initialize(**opts = {})
    #   @param [Hash] opts the options or keyword value Hash
    #   @option opts [Integer] :id a Character ID
    #   @option opts [Hash] :states a Hash of `taxon_ID => text_state`
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

    # @return [Integer] the ID of the character
    attr_reader :id

    # @!attribute [r] taxa
    # @return [Array] the list of taxon IDs
    def taxa
      taxa_states.keys
    end

    # @return [Hash] the Hash of character state frequencies, keyed by symbol
    attr_reader :frequency

    # @return [Hash] the Hash of text states, keyed by symbol
    attr_reader :states

    # @param  symbol [String] a symbol associated with a character state
    # @return [String] the text state associated with the character state
    def state(symbol)
      states[normalize_text(symbol)]
    end

    # @!attribute [r] symbols
    # @return [Hash] the Hash of symbols, keyed by text state
    def symbols
      @symbols ||= states.invert.freeze
    end

    # @param state [String] a text state associated with a character state
    # @return [String] the symbol associated with the character state
    def symbol(state)
      symbols[normalize_text(state)]
    end

    # @return [Hash] the Hash of text states, keyed by taxon
    attr_reader :taxa_states

    # @param  taxon [Integer] a taxon ID
    # @return [String] the text state associated with the taxon's character state
    def taxa_state(taxon)
      taxa_states[taxon]
    end

    # @!attribute [r] taxa_symbols
    # @return [Hash] a Hash of symbols, keyed by taxa IDs
    def taxa_symbols
      @taxa_symbols ||= (taxa_states.each_with_object({}) do |(taxon, state), acc|
        acc[taxon] = symbols[state]
      end).freeze
    end

    # @param  taxon [Integer] a taxon ID
    # @return [String] the symbol associated with the taxon's character state
    def taxa_symbol(taxon)
      taxa_symbols[taxon]
    end

    # @!attribute [r] states_taxa
    # @return [Hash] a Hash of taxa, keyed by text state
    def states_taxa
      @states_taxa ||= (states.each_with_object({}) do |(_symbol, state), acc|
        acc[state] = taxa_states.select { |_taxon, tstate| state == tstate }.keys
      end).freeze
    end

    # @!attribute [r] symbols_taxa
    # @return [Hash] a Hash of taxa, keyed by symbol
    def symbols_taxa
      @symbols_taxa ||= (states_taxa.each_with_object({}) do |(state, taxa), acc|
        acc[symbols[state]] = taxa
      end).freeze
    end

    # Pretty-print the object
    # (used by Pry in particular)
    def pretty_print(q)
      q.object_group(self) do
        q.breakable
        q.group(1) do
          q.text "@id=#{id}"
          q.breakable
          q.group(1, "{", "}") do
            q.seplist(states) do |symbol, state|
              q.text %(#{state.inspect}(#{symbol})=#{states_taxa[state]})
            end
          end
        end
      end
    end

    # @return [String] a string representation of the object.
    def inspect
      pretty_inspect.chomp
    end
    alias to_s inspect

    private

    # @param text [String] an arbitrary string of text
    # @return [String] a Unicode-normalized, stripped, frozen copy
    def normalize_text(text)
      text = UNF::Normalizer.normalize(text.to_s, :nfc)
      text.strip!
      text.freeze
    end

    # Find all unique elements in an array and stably sort them by frequency.
    # @param array [Array]
    # @return [Hash] keys are unique input array elements, values are frequency
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
