# frozen_string_literal: true
module Dphil
  module VerseAnalysis
    module Regexes
      vow = "aAiIuUfFxXeEoO"
      con = "kKgGNcCjJYwWqQRtTdDnpPbBmyrlvzSsh"
      add = "MH"

      SYL_R = /[']?[#{con}]*[#{vow}][#{con}#{add}]*(?![#{vow}])\s*/
      G_VOW_R = /[AIUFXeEoO]|[MH]$/
      G_CON_R = /[#{con}]{2}/
    end

    module_function

    def syllables(str)
      str = str.gsub(/[\|\.\,\\0-9]+/, "").strip
      str.gsub!(/\s+/, " ")
      str = Transliterate.iast_slp1(str)

      syllables = str.scan(Regexes::SYL_R)
      syllables.map { |syl| Transliterate.slp1_iast(syl) }
    end

    def syllable_weight(syllables)
      syllables = syllables.map { |syl| Transliterate.iast_slp1(syl) }
      weight_arr = []
      (0...syllables.length).each do |i|
        cur_syl = syllables[i].to_s.delete("'").strip
        next_syl = syllables[i + 1].to_s.delete("'").strip

        weight_arr << if cur_syl =~ Regexes::G_VOW_R
                        # Guru if current syllable contains a long vowel or end in a ṃ or ḥ
                        "G"
                      elsif "#{cur_syl[-1]}#{next_syl&.slice(0)}" =~ Regexes::G_CON_R
                        # Guru if current syllable ends in a consonant cluster (look ahead)
                        "G"
                      else
                        "L"
                      end
      end
      weight_arr.join("")
    end

    def verse_weight(str)
      syllable_weight(syllables(str))
    end
  end
end
