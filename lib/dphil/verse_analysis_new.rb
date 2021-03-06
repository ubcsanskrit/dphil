# frozen_string_literal: true

require "amatch"

module Dphil
  module VerseAnalysis
    using ::Ragabash::Refinements

    module_function

    # Converts a verse string into individual syllables.
    #
    # @param verse_string [String] the raw text of the verse.
    # @param from [Symbol] specify source transliteration scheme (detect by default)
    # @param to [Symbol] specify output transliteration scheme (defaults to source)
    # @return [Array] the text split into individual SLP1-encoded syllables.
    def syllables(verse_string, from: nil, to: nil)
      verse_string = verse_string.to_str.gsub(/[\|\.\,\\0-9]+/, "").gsub(/\s+/, " ").strip
      from ||= Transliterate.detect(verse_string) || Transliterate.default_script
      to ||= from
      verse_string = Transliterate.transliterate(verse_string, from, :slp1)
      syllables = verse_string.scan(Constants::R_SYL)
      syllables.map! { |syl| Transliterate.transliterate(syl, :slp1, to) } if to != :slp1
      syllables
    end

    # Converts a list of syllables into their L/G weights.
    #
    # @param syllables [Array] a set of syllables
    # @return [String] the weight string of the syllables of the verse
    def syllables_weights(syllables, from: nil, contextual: false)
      from ||= Transliterate.detect(syllables.join("")) || Transliterate.default_script
      syllables = syllables.to_ary.map { |syl| Transliterate.transliterate(syl, from, :slp1) } if from != :slp1
      weight_arr = (0...syllables.length).map do |i|
        cur_syl = syllables[i].delete("'").strip
        next_syl = syllables[i + 1]&.delete("'")&.strip
        if cur_syl.match?(Constants::R_GSYL)
          # Guru if current syllable contains a long vowel, or end in a ṃ/ḥ
          "G"
        elsif cur_syl.match?(Constants::R_CCONF)
          # Contextually Guru if ending in a cluster
          "g"
        elsif "#{cur_syl[-1]}#{next_syl&.slice(0)}".match?(Constants::R_CCON)
          # Contextually Guru if syllable-final and next syllable-inital make a
          # consonant cluster.
          "g"
        else
          "L"
        end
      end
      contextual ? weight_arr.join("") : weight_arr.join("").upcase
    end

    # Convenience method to directly get weight string of verse
    #
    # @param verse_string [String] the raw text of the verse
    # @return [String] the weight string of the verse.
    def verse_weights(verse_string, contextual: false)
      syllables_weights(syllables(verse_string), contextual: contextual)
    end

    def identify(verse_string)
      v_syllables = syllables(verse_string)
      v_weight = syllables_weights(v_syllables, contextual: true)
      v_meters = identify_meter_manager(verse_string)
      unless v_meters.empty?
        status = v_meters.first[:info]
        meter = status.delete(:meter)
        padas = v_meters.first[:corrected_padas]
      end
      {
        verse: verse_string,
        syllables: v_syllables,
        weights: v_weight,
        status: status,
        meter: meter,
        padas: padas,
      }
    end

    # Coordinates metrical identification for a verse string.
    #
    # @param verse_string [String] a verse string
    # @return [Array] candidate meters and information about their matches
    def identify_meter_manager(verse_string)
      syllables = syllables(verse_string)
      weight_string = syllables_weights(syllables)

      candidates = []
      4.downto(1).each do |guess_size|
        #
        # TODO: Pre-process or somehow change this so that search is aware of
        #       how weight_string may or may not break across padas
        #       (i.e. whitespace in syllables)
        search_results = meter_search_partial(weight_string, guess_size)
        next if search_results.empty?

        meter_results = search_results.group_by { |result| result[:meter_name] }

        # Filter down to most-complete matches for each meter.
        meter_results = compact_meter_results(meter_results)
        meter_results.sort_by { |_key, value| value[0][:match_percent] }.to_h

        meter_results = fuzzy_manager(meter_results, guess_size, weight_string)

        # Add results to candidates
        candidates.concat(meter_results)
      end

      candidates.concat(fuzzy_analysis(weight_string, 4, 0)) if candidates == []

      candidates.sort_by! { |value| value[:heuristic] }
      candidates.reverse!
      probables = get_best_matches(candidates, syllables, 2)
      probables
    end

    #
    #
    #
    #
    def get_best_matches(candidates, syllables, number)
      best = []
      i = 1
      candidates.each do |val|
        break if i > number

        acc = {
          info: val,
          corrected_padas: fuzzy_correction(val[:meter], val[:correct_weights], syllables),
        }
        i += 1
        best << acc
      end
      best
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
          i_end = match + pattern.length - 1
          indexes << (match..i_end)
          i = i_end + 1
        end
      when Regexp
        while (match = pattern.match(weight_string, i))
          i_start = match.begin(0)
          i_end = i_start + match[0].length - 1
          indexes << (i_start..i_end)
          i = i_end + 1
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

    # Checks whether or not a range overlaps with an array of ranges
    #
    # @param indexes [Array] Array of ranges
    # @param range []
    # @return []
    def check_non_overlapping?(indexes, range)
      return true if indexes.empty?

      indexes.each do |val|
        return false if val.cover?(range.begin) || val.cover?(range.end)
      end
      true
    end

    # Filters out redundant meter results by compiling together the most
    #   complete possible matches for each meter.
    #
    # @param meter_results [Hash] a hash of search results grouped by meter
    # @return [Hash] a compacted hash of search results grouped by meter
    def compact_meter_results(meter_results)
      compact_results = {}

      meter_results.keys.each do |meter_name|
        compact_index = []
        p = 0
        meter_results[meter_name].each do |val|
          val[:matches].each do |i|
            next unless check_non_overlapping?(compact_index, i)
            compact_index << i
            case val[:size]
            when :full
              p += 100
            when :half
              p += 50
            when :pada
              p += 25
            end
          end
        end
        acc = {
          pattern_type: meter_results[meter_name][0][:type],
          matches: compact_index.sort_by { |a| a.to_s.split("..").first.to_i },
          match_percent: p,
        }
        compact_results[meter_name] = [acc]
      end
      compact_results
    end

    #
    #
    #
    #
    def fuzzy_manager(meter_results, guess_size, weight_string)
      w1 = weight_string.dup
      extended_result = []
      e = 0

      meter_results.each do |key, val|
        break if e == 1
        wc = w1.dup
        indexes = val[0][:matches]
        q = (val[0][:match_percent] * 100) / (guess_size * 25)

        q += 25 if q == 50 && guess_size == 2 # to deal with problematic case when p=25 and guess=2, should be only one correction

        case q
        when 100
          wc = remove_extra_syllables(wc, indexes)
          e = 1
        when 60..75
          max = get_unmatched_range(indexes, wc.length - 1)
          portion = wc.slice!(max.begin, (max.end - max.begin + 1))
          pattern = get_specific_pattern(key, :pada, val[0][:pattern_type], portion)
          correct = corrected_string(portion, pattern)
          wc.insert(max.begin, correct)
          indexes = update_index_array(indexes, max, correct.length - portion.length)
          wc = remove_extra_syllables(wc, indexes)

        when 30..50
          flag = 0
          2.times do
            next if flag == 1
            max = get_unmatched_range(indexes, wc.length - 1)
            portion = wc.slice!(max.begin, (max.end - max.begin + 1))
            if (max.end - max.begin + 1) > ((metercount[key][4] / 4) + 3)
              pattern = get_specific_pattern(key, :half, val[0][:pattern_type], portion)
              flag = 1
            else
              pattern = get_specific_pattern(key, :pada, val[0][:pattern_type], portion)
            end
            correct = corrected_string(portion, pattern)
            wc.insert(max.begin, correct)
            indexes = update_index_array(indexes, max, correct.length - portion.length)
          end
          wc = remove_extra_syllables(wc, indexes)
        else
          best_fuzzy = fuzzy_analysis(w1, guess_size, val[0][:match_percent])
          best_fuzzy.each do |v|
            if v[:meter] == key
              extended_result << v
              next
            end
          end
          (0...wc.length).each do |k|
            wc[k] = "x"
          end
        end

        status = get_pada_status(key, wc, indexes, guess_size)
        pada_weights = get_weight_by_pada(status, wc)

        acc = {
          len_assumption: guess_size.to_s + "/4",
          meter: key,
          type: val[0][:pattern_type],
          match_indexes: status,
          percent_match: val[0][:match_percent],
          edit_count: wc.scan(/[a-z]/).length,
          correct_weights: pada_weights,
          heuristic: (2 * val[0][:match_percent]) + ((100 - (wc.scan(/[a-z]/).length * 100 / weight_string.length))),
        }
        extended_result << acc
      end
      extended_result
    end

    #
    #
    #
    #
    def get_pada_status(meter, correct_weights, indexes, guess_size)
      len = metercount[meter]
      cw = correct_weights.dup
      index = indexes.dup

      status = []
      range = nil

      pn = -1
      pr = nil
      ps = ""

      # TO DO : identify which padas are actually missing
      (1..guess_size).each do |i|
        break if range.nil? && index.empty?
        pn = i
        range = index.slice!(0, 1)[0] if range.nil?

        if cw.slice(range.begin, range.end - range.begin + 1).scan(/[a-z]/).empty?
          ps = "exact"
          if (range.end - range.begin + 1) == len[i - 1]
            pr = range
            range = nil
          else
            pr = (range.begin..(range.begin + len[i - 1] - 1))
            range = ((range.begin + len[i - 1])..range.end)
          end
        else
          ps = "fuzzy"
          temp = 1
          rng = range.begin
          while temp <= len[i - 1]
            temp += 1 if cw[rng] != "d"
            rng += 1
          end
          if rng > range.end
            pr = range
            range = nil
          else
            pr = (range.begin..(rng - 1))
            range = (rng..range.end)
          end
        end
        acc = {
          pada_number: pn,
          pada_range: pr,
          pada_status: ps,
        }
        status << acc
      end

      ((guess_size + 1)..4).each do |j|
        pn = j
        pr = nil
        ps = "missing"
        acc = {
          pada_number: pn,
          pada_range: pr,
          pada_status: ps,
        }
        status << acc
      end
      status
    end

    #
    #
    #
    #
    def get_weight_by_pada(status, corrected_weights)
      cw = corrected_weights.dup
      pada_weights = []
      start = 0
      status.each do |val|
        if val[:pada_status] == "missing"
          pada_weights << ""
        else
          pada_weights << cw.slice(start, (val[:pada_range].end - start + 1))
          start = val[:pada_range].end + 1
        end
      end
      pada_weights
    end

    #
    #
    #
    #
    def fuzzy_analysis(weight_string, guess_size, per_match)
      wc = weight_string.dup
      best = []
      edits = 100

      meter_search_fuzzy(wc, guess_size).each do |value|
        edits = value[:edit_distance] if value[:edit_distance] < edits
      end

      meter_search_fuzzy(wc, guess_size).each do |value|
        next unless value[:edit_distance] == edits
        wc = corrected_string(weight_string, value[:pattern])
        status = get_pada_status(value[:meter], wc, [(0..(wc.length - 1))], guess_size)
        pada_weights = get_weight_by_pada(status, wc)
        acc = {
          len_assumption: guess_size.to_s + "/4",
          meter: value[:meter],
          type: value[:type],
          match_indexes: status,
          percent_match: per_match,
          edit_count: value[:edit_distance],
          correct_weights: pada_weights,
          heuristic: (2 * per_match) + ((100 - (value[:edit_distance] * 100 / weight_string.length))),
        }
        best << acc
      end
      best
    end

    #
    #
    #
    #
    def get_specific_pattern(meter_name, size, type, weight_string)
      case type
      when :patterns
        if size == :pada
          MetricalData.meters[meter_name][0].dup
        else
          MetricalData.meters[meter_name][0].dup + MetricalData.meters[meter_name][1].dup
        end
      when :regexes
        MetricalData.all[type][size].each do |p, meter|
          next unless meter_name == meter.keys.first
          p = p.source.gsub(/[\^\$\(\)]/, "")
          r = closest_pattern_to_regex(weight_string, p)
          return r[:pattern]
        end
      end
    end

    #
    #
    #
    #
    def remove_extra_syllables(weights, indexes)
      w1 = weights.dup
      (0...w1.length).each do |u|
        flag = 0
        indexes.each do |v|
          flag = 1 if u >= v.begin && u <= v.end
        end
        w1[u] = "d" if flag == 0
      end
      w1
    end

    #
    #
    #
    #
    def get_unmatched_range(indexes, last)
      max = indexes[0].begin > (last - indexes[-1].end) ? (0..(indexes[0].begin - 1)) : ((indexes[-1].end + 1)..last)
      j = 0
      indexes.each do |i|
        if (i.begin - j - 1) > (max.end - max.begin + 1)
          max = ((j + 1)..(i.begin - 1))
        end
        j = i.end
      end
      max
    end

    #
    #
    #
    #
    def update_index_array(indexes, max, diff)
      indexes << max
      indexes = indexes.sort_by { |a| a.to_s.split("..").first.to_i }
      index2 = []
      indexes.each do |val|
        if val.begin < max.begin
          index2 << val
        elsif val.begin == max.begin
          index2 << ((max.begin)..(max.end + diff))
        else
          index2 << ((val.begin + diff)..(val.end + diff))
        end
      end
      index2
    end

    #
    #
    #
    #
    def corrected_string(weights, pattern)
      return weights if pattern.empty?
      actual = weights.split("")
      actual.insert(0, " ")
      pattern.insert(0, " ")

      table = Array.new(actual.length) { Array.new(pattern.length) }

      (0...actual.length).each do |i|
        table[i][0] = i
      end
      (0...pattern.length).each do |i|
        table[0][i] = i
      end

      (1...actual.length).each do |i|
        (1...pattern.length).each do |j|
          if actual[i] == pattern[j]
            table[i][j] = table[i - 1][j - 1]
          else
            table[i][j] = [table[i - 1][j], table[i - 1][j - 1], table[i][j - 1]].min + 1
          end
        end
      end

      correct = []
      i = actual.length - 1
      j = pattern.length - 1
      while i > 0 || j > 0
        if actual[i] == pattern[j]
          correct.insert(0, actual[i])
          i -= 1
          j -= 1
        else
          x = [table[i - 1][j], table[i - 1][j - 1], table[i][j - 1]].min if i > 0 && j > 0
          x = table[i][j - 1] if i == 0 # upper boundary case
          x = table[i - 1][j] if j == 0 # left boundary case
          case x
          when table[i][j - 1]
            if pattern[j] == "L"
              correct.insert(0, "l")
            else
              correct.insert(0, "g")
            end
            j -= 1
          when table[i - 1][j - 1]
            correct.insert(0, "f") # to mark substitution in string
            i -= 1
            j -= 1
          when table[i - 1][j]
            correct.insert(0, "d") # to mark deletion from string
            i -= 1
          end
        end
      end
      correct.join("")
    end

    #
    #
    #
    #
    def metercount
      @metercount ||= begin
        meter_data = {}
        MetricalData.meters.map do |meter_name, pada_arr|
          arr = pada_arr.map(&:length)
          arr << arr.reduce(&:+)
          meter_data[meter_name] = arr
        end
        MetricalData.regexes.full.each do |r, v|
          meter_name = v.keys.first
          next if meter_data.key?(meter_name)
          source = r.source
          next if source["|"] || source["("].nil?
          groups = source.scan(/\(([^()]*)\)/).flatten
          source.gsub!(/[\^\$\(\)]/, "")
          meter_data[meter_name] = groups.map(&:length) << source.length
        end

        meter_data.sort.to_h.deep_freeze
      end
    end

    #
    #
    #
    #
    def fuzzy_correction(_meter, corrected_weights, syllables)
      k = 0
      n = 0 # for syllables
      p = 0
      temp = []
      v_padas = []

      corrected_weights.each do |correct|
        (0...correct.length).each do |k|
          # break if n >= syllables.length
          if correct[k] == "d"
            temp << ("[" + syllables[n] + "]")
            n += 1
          elsif correct[k] == "f"
            temp << ("(" + syllables[n] + ")")
            n += 1
          elsif correct[k] == "g"
            case p
            when 0
              temp << " { (g)"
              p = 2
            else
              temp << "(g)"
            end
          elsif correct[k] == "l"
            case p
            when 0
              temp << " { (l)"
              p = 1
            else
              temp << "(l)"
            end
          else
            case p
            when 2
              if correct[k] == "L"
                temp << " } " + syllables[n]
                p = 0
              else
                temp << syllables[n]
              end
            when 1
              if correct[k] == "G"
                temp << " } " + syllables[n]
                p = 0
              else
                temp << syllables[n]
              end
            when 0
              temp << syllables[n]
            end
            n += 1
          end
        end
        v_padas << temp.join("")
        temp = []
      end
      v_padas
    end

    #
    #
    #
    #
    def meter_search_fuzzy(weight_string, guess_size)
      candidates = []
      syllable_count = weight_string.length
      length_variance = 0.2
      edit_tolerance = 0.15
      str = Amatch::Levenshtein.new(weight_string)

      %i[patterns regexes].each do |type|
        matches = MetricalData.all[type][:full].each_with_object([]) do |(p, meter), acc|
          meter_name = meter.keys.first
          case p
          when String
            pattern = ""
            p2 = p.dup
            l = metercount[meter_name]
            (0...guess_size).each do |i|
              pattern += p2.slice!(0, l[i])
            end

            next unless (pattern.length - syllable_count).abs <= length_variance * pattern.length
            edit_distance = str.match(pattern)
            next if edit_distance > edit_tolerance * pattern.length
            pattern_string = pattern
          when Regexp
            next if p.source["|"]
            p = p.source.gsub(/[\^\$\(\)]/, "")
            pattern = p.slice(0...(guess_size * p.length / 4))
            next if (pattern.length - syllable_count).abs > length_variance * pattern.length
            result = closest_pattern_to_regex(weight_string, pattern)
            pattern_string = result[:pattern]
            edit_distance = result[:edit_distance]

            next if edit_distance > edit_tolerance * pattern.length
          end
          acc << {
            meter: meter_name,
            type: type,
            guess_size: guess_size,
            pattern: pattern_string,
            edit_distance: edit_distance,
          }
        end
        candidates.concat(matches)
      end
      candidates
    end

    #
    #
    #
    #
    def closest_pattern_to_regex(weight_string, pattern)
      pattern2 = pattern.tr(".", "L")
      str = Amatch::Levenshtein.new(weight_string)

      edit_distance = str.match(pattern2)
      c = corrected_string(weight_string, pattern2)
      # c = c.join("")

      pattern_string = []
      x1 = 0 # for pattern
      xw = 0 # for weight string
      pattern = pattern.lstrip
      (0...c.length).each do |i|
        if c[i] == "L" || c[i] == "G"
          x1 += 1
          pattern_string << c[i]
          xw += 1
        elsif c[i] == "l"
          x1 += 1
          pattern_string << "L"
        elsif c[i] == "g"
          x1 += 1
          pattern_string << "G"
        elsif c[i] == "d"
          xw += 1
        elsif c[i] == "f" && pattern[x1] == "."
          x1 += 1
          edit_distance -= 1
          pattern_string << weight_string[xw]
          xw += 1
        else
          pattern_string << pattern[x1]
          x1 += 1
          xw += 1
        end
      end
      pattern_string = pattern_string.join("")
      acc = {
        pattern: pattern_string,
        edit_distance: edit_distance,
      }
      acc
    end
  end
end
