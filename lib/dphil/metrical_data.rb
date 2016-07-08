# frozen_string_literal: true
require "psych"
require "hashie"

module Dphil
  #
  # Metrical Data structure imported and parsed from "metrical_data" module at:
  # https://github.com/shreevatsa/sanskrit
  #
  module MetricalData
    class << self
      attr_reader :version, :meters, :patterns, :regexes, :all
    end

    private_class_method

    # This loads and processes the data into the module.
    def self.load_data!
      yml_data = Psych.load_file(File.join(GEM_ROOT, "vendor", "metrical_data.yml"))

      @version = yml_data["commit"].deep_freeze

      # Hash of meters with names as keys and patterns as values
      meters_h = yml_data["meters"].each_with_object({}) do |(name, patterns), h|
        h[Transliterate.unicode_downcase(name)] = patterns
      end
      @meters = IHash.new(meters_h)

      # Hash of meters with patterns for keys and names/padas as values
      patterns_h = yml_data["patterns"].each_with_object({}) do |(type, patterns), type_h|
        type_h[type.to_sym] = patterns.each_with_object({}) do |(pattern, meters), pattern_h|
          pattern_h[pattern] = meters.each_with_object({}) do |(name, value), name_h|
            name_h[Transliterate.unicode_downcase(name)] = value
          end
        end
      end
      @patterns = IHashM.new(patterns_h)

      # Hash of meters with regular expressions for keys and names/padas as values
      regexes_h = yml_data["regexes"].each_with_object({}) do |(type, patterns), type_h|
        type_h[type.to_sym] = patterns.each_with_object({}) do |(pattern, meters), pattern_h|
          pattern_h[pattern] = meters.each_with_object({}) do |(name, value), name_h|
            name_h[Transliterate.unicode_downcase(name)] = value
          end
        end
      end
      @regexes = IHashM.new(regexes_h)

      @all = IHashM.new(version: version,
                        meters: meters,
                        patterns: patterns,
                        regexes: regexes)
      self
    end

    # Immutable Hash
    class IHash < ::Hash
      include Hashie::Extensions::MergeInitializer

      def initialize(*)
        super
        deep_freeze
      end
    end

    # Immutable Hash with method access (for :full, :half, :pada hashes)
    class IHashM < IHash
      include Hashie::Extensions::MethodAccess
    end

    # Load the data when we load the module
    # (but keep it in a method for cleanliness)
    load_data!
  end
end
