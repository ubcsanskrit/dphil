# frozen_string_literal: true
require "amatch"

module Dphil
  using Helpers::Refinements
  module VerseAnalysis
    module_function

    # Converts a verse string into individual syllables.
    #
    # @param verse_string [String] the raw text of the verse.
    # @return [Array] the text split into individual SLP1-encoded syllables.
    def syllables(verse_string)
      verse_string = verse_string.to_str.gsub(/[\|\.\,\\0-9]+/, "").gsub(/\s+/, " ").strip
      verse_string = Transliterate.iast_slp1(verse_string)
      syllables = verse_string.scan(Constants::R_SYL)
      syllables.map { |syl| Transliterate.slp1_iast(syl) }
    end

    # Converts a list of syllables into their L/G weights.
    #
    # @param syllables [Array] a set of syllables
    # @return [String] the weight string of the syllables of the verse
    def syllables_weights(syllables)
      syllables = syllables.to_ary.map { |syl| Transliterate.iast_slp1(syl) }
      weight_arr = (0...syllables.length).map do |i|
        cur_syl = syllables[i].delete("'").strip
        next_syl = syllables[i + 1]&.delete("'")&.strip
        if cur_syl =~ Constants::R_GSYL
          # Guru if current syllable contains a long vowel, or end in a ṃ/ḥ/conjunct
          "G"
        elsif "#{cur_syl[-1]}#{next_syl&.slice(0)}" =~ Constants::R_CCON
          # Guru if current syllable ends in a consonant cluster (look ahead)
          "G"
        else
          "L"
        end
      end
      weight_arr.join("")
    end

    # Convenience method to directly get weight string of verse
    #
    # @param verse_string [String] the raw text of the verse
    # @return [String] the weight string of the verse.
    def verse_weights(verse_string)
      syllables_weights(syllables(verse_string))
    end

    # Coordinates metrical identification for a vere string.
    #
    # @param verse_string [String] a verse string
    # @return [Array] candidate meters and information about their matches
    def identify_meter_manager(verse_string)
      syllables = syllables(verse_string)
      weight_string = syllables_weights(syllables)

      candidates = []
      4.downto(1).each do |guess_size|
        search_results = meter_search_partial(weight_string, guess_size)
        next if search_results.empty?

        meter_results = search_results.group_by { |result| result[:meter_name] }

        # Filter down to most-complete matches for each meter.
        meter_results = compact_meter_results(meter_results)

        # Add results to candidates
        candidates.concat(meter_results.values)
      end
      candidates
    end

    # Searches for meter candidates for a given weight string and search size.
    #
    # @param weight_string [String] a weight string
    # @param guess_size [Integer] the number of padas to match against
    # @return [Array] candidate meters and associated match data
    def meter_search_partial(weight_string, guess_size)
      size_groups = if guess_size == 4
                      %i[full half pada]
                    elsif guess_size >= 2
                      %i[half pada]
                    else
                      %i[pada]
                    end

      candidates = []
      size_groups.product(%i[patterns regexes]).each do |(pattern_size, pattern_type)|
        MetricalData.all[pattern_type][pattern_size].each do |pattern, meter|
          next unless useful_comparison?(weight_string, pattern, pattern_size, guess_size)
          # Match pattern against weight_string by `.find_pattern`
          matches = find_pattern(weight_string, pattern)
          next if matches.empty?
          candidates << {
            meter_name: meter.each_key.first,
            type: pattern_type,
            size: pattern_size,
            scope: meter.each_value.first,
            pattern: pattern,
            matches: matches,
            coverage: matches.reduce(0.0) { |a, e| a + e.size } / weight_string.length,
            guess_size: guess_size,
          }
        end
      end
      candidates
    end

    # Determines whether a given match might be considered useful to determining
    #   a candidate meter for a given weight string.
    #
    # @param weight_string [String] a weight string
    # @param pattern [String, Regexp] a match pattern
    # @param pattern_size [Symbol] the size of a match pattern
    # @param guess_size [Integer] the number of padas being searched for
    # @param tolerance [Numeric] the tolerance percentage of length difference
    #
    # @return [Boolean] true if comparison has good chance of being useful
    def useful_comparison?(weight_string, pattern, pattern_size, guess_size, tolerance = 0.2)
      pattern = clean_regexp_pattern(pattern) if pattern.is_a?(Regexp)
      multiplier = pattern_size_multiplier(pattern_size)
      difference = (weight_string.length - (guess_size * multiplier * pattern.length / 4)).abs
      return true if difference <= (tolerance * multiplier * pattern.length)
      false
    end

    # Finds all occurrences of a match pattern in a weight string
    #
    # @param weight_string [String] a weight string
    # @param pattern [String, Regexp] a match pattern
    # @return [Array] array of index-ranges of pattern matches within weight string
    def find_pattern(weight_string, pattern)
      indexes = []
      i = 0
      case pattern
      when String
        while (match = weight_string.index(pattern, i))
          i_end = match + pattern.length
          indexes << (match...i_end)
          i = i_end
        end
      when Regexp
        while (match = pattern.match(weight_string, i))
          i_start = match.begin(0)
          i_end = i_start + match[0].length
          indexes << (i_start...i_end)
          i = i_end
        end
      end
      indexes
    end

    # Returns a string of a Regexp pattern cleaned of special characters
    #
    # @param regexp [Regexp] a regular expression
    # @return [String] a clean string of the pattern
    def clean_regexp_pattern(regexp)
      pattern = regexp.source
      pattern.gsub!(/[\(\)\^\$\|]+/, "")
      pattern
    end

    # Returns a multiplier based on the pattern size symbol
    #
    # @param pattern_size [Symbol] a pattern size symbol
    # @return [Integer] a multiplier
    def pattern_size_multiplier(pattern_size)
      case pattern_size
      when :full
        1
      when :half
        2
      when :pada
        4
      end
    end

    # Filters out redundant meter results by compiling together the most
    #   complete possible matches for each meter.
    #
    # @param meter_results [Hash] a hash of search results grouped by meter
    # @return [Hash] a compacted hash of search results grouped by meter
    def compact_meter_results(meter_results)
      meter_results
    end
  end
end
