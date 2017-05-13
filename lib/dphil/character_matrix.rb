# frozen_string_literal: true

module Dphil
  #
  # A matrix of character states across taxa.
  #
  class CharacterMatrix
    include LDOutput

    # Instantiate a new CharacterMatrix from a UTF-8 CSV file
    # @param infile [#read] the file/IO object to read
    # @param transpose [Boolean] transpose the table 90° (headers in first column)
    # @return [CharacterMatrix]
    def self.from_csv(infile, transpose: false)
      csv = CSV.read(infile, "r:bom|utf-8")
      csv = csv.transpose if transpose
      new(csv)
    end

    # Instantiate a new CharacterMatrix
    # @param table [Array<Array<String>>] collation table (headers in first row)
    def initialize(table)
      @taxa_names = table.to_a.first.each_with_object({})
                         .with_index do |(name, acc), index|
        acc[index + 1] = normalize_text(name)
      end
      @taxa_ids = @taxa_names.invert

      taxa_arr = @taxa_ids.values
      @characters = (1...table.length).each_with_object({}) do |char_num, acc|
        char_states = taxa_arr.zip(table[char_num]).to_h
        acc[char_num] = Dphil::Character.new(id: char_num, states: char_states)
      end

      instance_variables.each { |ivar| instance_variable_get(ivar).freeze }
    end

    # @!attribute [r] taxa_names
    # @return [Hash<Integer, String>] taxa names by ID
    attr_reader :taxa_names

    # @!attribute [r] taxa_ids
    # @return [Hash<String, Integer>] taxa IDs by names
    attr_reader :taxa_ids

    # @!attribute [r] characters
    # @return [Hash<Integer, Character>] characters by character ID
    attr_reader :characters

    # @!attribute [r] stats
    # @return [Hash] the character statistics for the matrix
    def stats
      @stats ||= begin
        hash = {
          total: characters.count,
          constant: 0,
          uninformative: 0,
          informative: 0,
        }
        characters.each_value do |char|
          if char.constant?
            hash[:constant] += 1
          elsif char.informative?
            hash[:informative] += 1
          else
            hash[:uninformative] += 1
          end
        end
        hash
      end.freeze
    end

    # Get character by ID
    # @param char_id [Integer] a character ID
    # @return [Character, nil] the associated Character, or Nil if not found.
    def get_character(char_id)
      characters[char_id.to_i]
    end

    def to_h
      {
        taxa_names: taxa_names,
        characters: characters.transform_values(&:to_h),
      }
    end

    def as_json(*args)
      to_h.as_json(*args)
    end

    def to_json(*args)
      as_json(*args).to_json(*args)
    end

    private

    # @param text [String] an arbitrary string of text
    # @return [String] a Unicode-normalized, stripped, frozen copy
    def normalize_text(text)
      return if text.nil?
      text = UNF::Normalizer.normalize(text.to_s, :nfc)
      text.strip!
      text.freeze
    end
  end
end
