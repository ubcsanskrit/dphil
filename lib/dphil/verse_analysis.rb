# frozen_string_literal: true
module Dphil
  module VerseAnalysis
    module_function

    def syllables(str)
      vowel_match = /[aAiIuUfFxXeEoO]/ # /a|e|i|o|u|f|ḷ|ā|ṝ|ī|ū/s
      str = Dphil::Transliterate.iast_slp1(str)

      start = -1
      indices = []
      while start = str.index(vowel_match, start + 1)
        indices << start
      end

      indices[0] = 1
      indices << str.length + 1
      (1...indices.length).map do |i|
        Dphil::Transliterate.slp1_iast(str.slice!(0, indices[i] - indices[i - 1]))
      end
    end

    def syllable_weight(syllables_array)
      syllables_array.map do |syl|
        Dphil::Transliterate.iast_slp1(syl)[-1, 1] =~ /[aiufx]/ ? "l" : "g"
      end
    end
  end
end
