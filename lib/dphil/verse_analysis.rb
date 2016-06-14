# frozen_string_literal: true
module Dphil
  module VerseAnalysis
    module_function

    def syllables(str)
      vowel_match = /[aAiIuUfFxXeEoO]/ # /a|e|i|o|u|f|ḷ|ā|ṝ|ī|ū/s
      str = Transliterate.iast_slp1(str.gsub(%r{[\|\.\,/'\s\\]+}, ""))

      indices = (0...str.length).each_with_object([]) do |index, acc|
        acc << index if str[index] =~ vowel_match
      end

      indices[0] = 1
      indices << str.length + 1
      (1...indices.length).map do |i|
        Transliterate.slp1_iast(str.slice!(0, indices[i] - indices[i - 1]))
      end
    end

    def syllable_weight(syllables_array)
      weight_arr = syllables_array.map do |syl|
        Transliterate.iast_slp1(syl)[-1, 1] =~ /[aiufx]/ ? "L" : "G"
      end
      weight_arr.join("")
    end

    def verse_weight(str)
      syllable_weight(syllables(str))
    end
  end
end
