# frozen_string_literal: true

module Dphil
  #
  # Phylogenetic character for storing states and symbols.
  #
  # Immutable.
  #
  class Character
    include Dphil::LDOutput

    # Instantiates a new Character
    # @overload initialize(id = nil, states = nil)
    #   @param id [Integer] a character ID
    #   @param states [Hash<Integer, String]] taxa and text-states +{ taxon_id => text_state }+
    # @overload initialize(**opts = {})
    #   @param [Hash] opts options or keyword values
    #   @option opts [Integer] :id a character ID
    #   @option opts [Hash<Integer, String]] :states taxa and text-states +{ taxon_id => text_state }+
    def initialize(id = nil, states = nil, **opts)
      @id = (opts[:id] || id)&.to_s.to_i
      @taxa_states = (opts[:states] || states)
                     .to_h.each_with_object({}) do |(taxon, state), acc|
        next if state.blank?
        taxon = taxon.to_s if taxon.is_a?(Symbol)
        acc[taxon.to_i] = normalize_text(state)
      end

      unique_states = weighted_uniq(@taxa_states.values)
      if unique_states.size > SYMBOL_ARRAY.size
        raise ArgumentError,
              "Too many states (found #{unique_states.size}, " \
              "max #{SYMBOL_ARRAY.size})"
      end

      @states = {}
      @state_totals = unique_states
      unique_states.each_key.with_index do |state, index|
        @states[SYMBOL_ARRAY[index]] = state
      end
      instance_variables.each { |ivar| instance_variable_get(ivar).freeze }
    end

    # @!attribute [r] id
    # @return [Integer] character ID
    attr_reader :id

    # @!attribute [r] taxa
    # @return [Set<Integer>] taxon IDs
    def taxa
      @taxa ||= Set.new(taxa_states.keys).freeze
    end

    # @!attribute [r] states
    # @return [Hash<String, String>] text-states by symbol
    attr_reader :states

    # @!attribute [r] symbols
    # @return [Hash<String, String>] symbols by text-state
    def symbols
      @symbols ||= states.invert.freeze
    end

    # @!attribute [r] state_list
    # @return [Array<String>] text-states
    def state_list
      @state_list ||= states.values.freeze
    end

    # @!attribute [r] symbol_list
    # @return [Array<String>] symbols
    def symbol_list
      @symbol_list ||= states.keys.freeze
    end

    # @!attribute [r] state_totals
    # @return [Hash<String, Integer>] character state totals by text-state
    attr_reader :state_totals

    # @!attribute [r] symbol_totals
    # @return [Hash<String, Integer>] character state totals by symbol
    def symbol_totals
      @symbol_totals ||= state_totals.transform_keys { |state| symbols[state] }.freeze
    end

    # @!attribute [r] taxa_states
    # @return [Hash<Integer, String>] text-states by taxon ID
    attr_reader :taxa_states

    # @!attribute [r] taxa_symbols
    # @return [Hash<Integer, String>] symbols by taxon ID
    def taxa_symbols
      @taxa_symbols ||= taxa_states.transform_values { |state| symbols[state] }.freeze
    end

    # @!attribute [r] states_taxa
    # @return [Hash<String, Integer>] taxa IDs by text-state
    def states_taxa
      @states_taxa ||= (states.each_value.each_with_object({}) do |state, acc|
        acc[state] = taxa_states.select { |_, tstate| state == tstate }.keys
      end).freeze
    end

    # @!attribute [r] symbols_taxa
    # @return [Hash<String, Integer>] taxa IDs by symbol
    def symbols_taxa
      @symbols_taxa ||= states_taxa.transform_keys { |state| symbols[state] }.freeze
    end

    # Get state from symbol
    # @param  symbol [String] a symbol
    # @return [String, nil] the associated text-state, or Nil if not found
    def get_state(symbol)
      states[normalize_text(symbol)]
    end

    # Get symbol from state
    # @param state [String] a text-state
    # @return [String, nil] the associated symbol, or Nil if not found
    def get_symbol(state)
      symbols[normalize_text(state)]
    end

    # Get taxa from state
    # @param  symbol [String] a text-state
    # @return [Array<Integer>] the associated taxa IDs
    def get_taxa_state(state)
      states_taxa[normalize_text(state)]
    end

    # Get taxa from symbol
    # @param  symbol [String] a symbol
    # @return [Array<Integer>] the associated taxa IDs
    def get_taxa_symbol(symbol)
      symbols_taxa[normalize_text(symbol)]
    end

    # Get state from taxon
    # @param  taxon_id [Integer] a taxon ID
    # @return [String, nil] the associated text-state, or Nil if not found
    def get_state_taxon(taxon_id)
      taxa_states[taxon_id.to_i]
    end

    # Get symbol from taxon
    # @param  taxon_id [Integer] a taxon ID
    # @return [String, nil] the associated symbol, or Nil if not found
    def get_symbol_taxon(taxon_id)
      taxa_symbols[taxon_id.to_i]
    end

    # Check if character is parsimony-informative
    # (At least 2 variants occurring in at least 2 places)
    # @return [Boolean] whether the character provides useful information
    def informative?
      @informative ||= (states.size > 1 && states_taxa.count { |_, v| v.size > 1 } > 1)
    end

    # Check if the character is invariant
    # @return [Boolean] whether the character is constant (invariant)
    def constant?
      @constant ||= states.size <= 1
    end

    def to_h
      {
        id: id,
        states: states,
        symbols: symbols,
        state_totals: state_totals,
        taxa_states: taxa_states,
        states_taxa: states_taxa,
        is_informative: informative?,
        is_constant: constant?,
      }
    end

    def as_json(*args)
      to_h.as_json(*args)
    end

    def to_json(*args)
      as_json(*args).to_json(*args)
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
              q.text "#{state.inspect}(#{symbol})=#{states_taxa[state]}"
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
      return if text.nil?
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
