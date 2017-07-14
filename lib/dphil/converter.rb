# frozen_string_literal: true

module Dphil
  #
  # Base module for file converters (CSV, NEXUS, CollateX, etc.)
  #
  module Converter
    private

    # Load a file
    def load_file(infile)
      raise IOError, "File #{infile} not found." unless File.exist?(infile)
      File.read(infile)
    end

    # Load a CSV file
    def load_csv(infile, mode = "r")
      raise IOError, "File #{infile} not found." unless File.exist?(infile)
      CSV.read(infile, mode)
    end

    # Return a hash of array sorted/weighted by number of identical entries
    def weighted_uniq(array)
      weighted_hash = array.each_with_object({}) do |v, acc|
        acc[v] ||= 0
        acc[v] += 1
      end
      n = 0
      (weighted_hash.sort_by do |x|
        n += 1
        [-x[1], n]
      end).to_h
    end

    # Sanitize a character string to basic KH/ASCII
    def sanitize_char(str)
      str = str.to_s
      src = Sanscript.detect(str) || :iast
      str = Sanscript.transliterate(str, src, :kh)
      str.gsub!(/\s/, "_")
      str.tr!("'", "`")
      str.strip!
      str
    end

    # Tokenize the values of a character
    def tokenize(characters)
      char_set = weighted_uniq(characters.map { |c| sanitize_char(c) }.reject(&:empty?))
      char_set.each_with_object({}).with_index do |(char, acc), i|
        acc[char[0]] = [ALPHABET[i], char[1]]
      end
    end

    # NEX Token Alphabet
    ALPHABET = IceNine.deep_freeze(("A".."Z").to_a + ("a".."z").to_a)
    private_constant :ALPHABET
  end
end
