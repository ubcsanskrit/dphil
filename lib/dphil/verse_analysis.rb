# frozen_string_literal: true
require "json"
require "amatch"

module Dphil
  using Helpers::Refinements
  module VerseAnalysis
    module_function

    include Amatch

    def syllables(str)
      str = str.to_str
      Dphil.cache("VerseAnalysis.syllables", str) do
        str = str.gsub(/[\|\.\,\\0-9]+/, "").gsub(/\s+/, " ").strip
        str = Transliterate.iast_slp1(str)
        syllables = str.scan(Constants::R_SYL)
        syllables.map { |syl| Transliterate.slp1_iast(syl) }
      end
    end

    def syllables_weights(syllables)
      syllables = syllables.to_ary
      Dphil.cache("VerseAnalysis.syllables_weights", syllables) do
        syllables = syllables.map { |syl| Transliterate.iast_slp1(syl) }
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
    end

    def verse_weight(str)
      Dphil.cache("VerseAnalysis.verse_weight", str) do
        syllables_weights(syllables(str))
      end
    end

    #
    #
    # WIP BEGIN
    #
    #

    # Search through MetricalData and return candidate matches
    def meter_search_exact(weight_string, size = :full, padas = [1, 2, 3, 4])
      # FIXME: Only considers full weight string, so only useful for full patterns
      candidates = []
      %i[patterns regexes].each do |type|
        matches = MetricalData.all[type][size].each_with_object([]) do |(pattern, meter), acc|
          meter_name = meter.keys.first
          meter_scope = meter.values.first
          case pattern
          when String
            next unless weight_string == pattern
            pattern_string = pattern
          when Regexp
            r_match = pattern.match(weight_string)
            next if r_match.nil?
            pattern_string = r_match.length > 1 ? r_match.captures : r_match.to_s
          end
          acc << {
            meter: meter_name,
            type: "#{type}",
            size: "#{size}",
            pattern: pattern_string,
            scope: meter_scope,
            padas: padas,
          }
        end
        candidates.concat(matches)
      end
      # candidates = candidates.uniq
      candidates
    end

    def meter_search_fuzzy(weight_string, size = :full)
      candidates = []
      syllable_count = weight_string.length
      length_variance = 5
      edit_tolerance = 5
      str = Levenshtein.new(weight_string)

      %i[patterns regexes].each do |type|
        matches = MetricalData.all[type][size].each_with_object([]) do |(pattern, meter), acc|
          meter_name = meter.keys.first
          # meter_scope = meter.values.first
          case pattern
          when String
            next unless (pattern.length - syllable_count).abs <= length_variance
            edit_distance = str.match(pattern)
            next if edit_distance > edit_tolerance
            pattern_string = pattern
          when Regexp # FIXME : approximate matching in case of regexes
            next if pattern.source["|"]
            pattern = pattern.source.gsub!(/[\^\$\(\)]/, "")
            next if (pattern.length - syllable_count).abs > length_variance
            pattern2 = pattern.gsub(".", "L")

            edit_distance = str.match(pattern2)
            c = corrected_string(weight_string, pattern2)
            c = c.join("")

            pattern_string = []
            x1 = 0 # for pattern
            xw = 0 # for weight string
            pattern = pattern.lstrip
            (0...c.length).each do |i|
              if (c[i] == "L" || c[i] == "G")
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
              elsif (c[i] == "f" && pattern[x1] == ".")
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
            next if edit_distance > edit_tolerance
          end
          acc << {
            meter: meter_name,
            type: type,
            size: size,
            pattern: pattern_string,
            edit_distance: edit_distance,
          }
        end
        candidates.concat(matches)
      end
      candidates
    end

    def weight_try_half(weight_string, meter)
      meter_hash = metercount
      length = meter_hash[meter]

      [
        weight_string.slice(0, length[0] + length[1]),
        weight_string.slice(length[0] + length[1], length[2] + length[3]),
      ]
    end

    def weight_try_pada(weight_string, meter)
      meter_hash = metercount
      length = meter_hash[meter]

      [
        weight_string.slice(0, length[0]),
        weight_string.slice(length[0], length[1]),
        weight_string.slice(length[0] + length[1], length[2]),
        weight_string.slice(length[0] + length[1] + length[2], length[3]),
      ]
    end

    def analyze_syllables(syllables)
      v_syllables = syllables.dup
      v_weight = syllables_weights(v_syllables)

      meter_candidates = {}

      meter_search_exact(v_weight).each do |val|
        if meter_candidates[val[:meter]].nil?
          meter_candidates[val[:meter]] = [val]
        else
          meter_candidates[val[:meter]] << val
        end
      end

      if meter_candidates == {}
        meter_search_fuzzy(v_weight).each do |val|
          if meter_candidates[val[:meter]].nil?
            meter_candidates[val[:meter]] = [val]
          elsif val[:edit_distance] < meter_candidates[val[:meter]][0][:edit_distance]
            meter_candidates[val[:meter]].clear
            meter_candidates[val[:meter]] << val
          end
        end
        status = "fuzzy match"
      else
        v_weight_halves = weight_try_half(v_weight, meter_candidates.keys.first)
        unless v_weight_halves.nil?
          v_weight_halves.each_with_index do |v_weight_half, index|
            padas = index == 0 ? [1, 2] : [3, 4]
            meter_search_exact(v_weight_half, :half, padas).each do |val|
              if meter_candidates[val[:meter]].nil?
                meter_candidates[val[:meter]] = [val]
              else
                meter_candidates[val[:meter]] << val
              end
            end
          end
        end

        v_weight_padas = weight_try_pada(v_weight, meter_candidates.keys.first)
        unless v_weight_padas.nil?
          v_weight_padas.each_with_index do |v_weight_pada, index|
            pada = [index + 1]
            meter_search_exact(v_weight_pada, :pada, pada).each do |val|
              if meter_candidates[val[:meter]].nil?
                meter_candidates[val[:meter]] = [val]
              else
                meter_candidates[val[:meter]] << val
              end
            end
          end
        end

        status = "exact match"
      end

      result = {
        status: status,
        syllables: v_syllables,
        weights: v_weight,
        meters: meter_candidates,
      }
      result
    end

    # identifies the most close meter and returns padas, any corrections in case of approx match
    def identify(verse_string)
      # 1. Get basic information about input
      v_syllables = syllables(verse_string)
      v_weight = syllables_weights(v_syllables)

      # 2. Discover possible meter candidates
      # Should return list of meters with relevant information for generating correction if appropriate.
      # (Including size of match, etc.)
      m = analyze_syllables(v_syllables)

      # 3. Explain meter candidates

      # 3.1 Exact match => Show meter name, information, split input according to match (if possible).

      # 3.2 Fuzzy match => Generate possible corrections between input and candidates

      # 4. Output object containing input data, result status, and candidate meters
      #    (with corrections if appropriate). No un-necessary results.

      meter_candidates = m[:meters]
      v_padas = []
      m_hsh = metercount

      if meter_candidates == {}
        m[:status] = "Verse highly defective , Can't find neter"
        v_meters = {}
        correct = []

      elsif m[:status] == "exact match"
        meter = meter_candidates.keys.first

        len = m_hsh[meter]
        v_padas << m[:syllables].slice!(0, len[0]).join("")
        v_padas << m[:syllables].slice!(0, len[1]).join("")
        v_padas << m[:syllables].slice!(0, len[2]).join("")
        v_padas << m[:syllables].slice!(0, len[3]).join("")

        defect_percentage = nil
        correct = []
      else
        d = 100.0
        pattern = []
        meter_candidates.each do |(key, val)|
          if val[0][:edit_distance].to_i < d #multiple verses with same edit distance???
            d = val[0][:edit_distance]
            meter = key
            pattern = val[0][:pattern].split("")
          end
        end

        defect_percentage = Rational(d, meter_candidates[meter][0][:pattern].length)
        n = fuzzy_correction(m[:weights], meter, pattern, m[:syllables])
        correct = n[:correct_weights]
        v_padas = n[:correct_padas]
      end

      v_corrections = {
        weights: correct.join(""),
        padas: v_padas,
      }

      v_meters = {
          name: meter,
          size: "full/half/pada",
          defectiveness: defect_percentage,
          corrections: [v_corrections],
      }

      result = {
        verse: verse_string,
        syllables: v_syllables,
        weights: v_weight,
        status: m[:status],
        meter: [v_meters],
      }

      if result[:status] == "exact match"
        result[:meter] = v_meters[:name]
        result[:padas] = v_padas
      end

      result
    end


    def corrected_string(weights, pattern)
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
            table[i][j] = ([table[i - 1][j], table[i - 1][j - 1], table[i][j - 1]].min) + 1
          end
        end
      end

      correct = []
      i = actual.length - 1
      j = pattern.length - 1
      while (i > 0 || j > 0)
        if actual[i] == pattern[j]
          correct.insert(0, actual[i])
          i -= 1
          j -= 1
        else
          x = [table[i - 1][j], table[i - 1][j - 1], table[i][j - 1]].min
          case x
          when table[i][j - 1]
            if pattern[j] == "L"
              correct.insert(0, "l")
            else
              correct.insert(0, "g")
            end
            j -= 1
          when table[i - 1][j - 1]
            correct.insert(0, "f")  #to mark substitution in string
            i -= 1
            j -= 1
          when table[i - 1][j]
            correct.insert(0, "d") # to mark deletion from string
            i -= 1
          end
        end
      end
      correct
    end


    def fuzzy_correction(weights, meter, pattern, syllables)
      correct = corrected_string(weights, pattern)

      k = 0
      n = 0
      p = 0
      temp = []
      v_padas = []
      len = metercount[meter].dup
      len.slice!(0, 4).each do |val|
        (1..val).each do
          if correct[k] == "d"    # still to figure out
            temp << ("(" + syllables[n] + ")")
            n += 1
          elsif correct[k] == "f"
            temp << ("(" + syllables[n] + ")")
            n += 1                  # still to figure out
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
          k += 1
        end
        v_padas << temp.join("")
        temp = []
      end

      result = {
        correct_weights: correct,
        correct_padas: v_padas,
      }
      result
    end

    # returns hash of meter names and no of syllables in each pada, total syllables
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

    def closeness
      e = []
      MetricalData.meters.keys.each do |key|
        first = MetricalData.meters[key].join("")
        a = Levenshtein.new(first)
        MetricalData.meters.keys.each do |key2|
          second = MetricalData.meters[key2].join("")
          diff = a.match(second)
          e << diff if diff <= 5
        end
        e = []
      end
      return nil
    end

    def find_mid(verse)
      w = verse_weight(verse)
      c = w.length
      min = c
      v = 0
      (((c / 2) - 3)..((c / 2) + 3)).each do |val|
        str = Levenshtein.new(w.slice(0, val))
        edit = str.match(w.slice(val, (c - val)))
        if edit < min
          min = edit
          v = val
        end
      end
      puts syllables(verse).slice(0, v).join("")
      puts syllables(verse).slice(v, (c - v)).join("")
    end
    #
    #
    # WIP END
    #
    #
  end
end
