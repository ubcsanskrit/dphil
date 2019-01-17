# frozen_string_literal: true

require "sanscript"

module Dphil
  # Transliteration module for basic romanization formats.
  module Normalize
    RULES = IceNine.deep_freeze(
      [
        {
          desc: "Retain control characters",
          search: /(\{\{.*?\}\})/,
          replace: [1],
        },
        {
          desc: "Punctuation -> X",
          search: %r{[\.\-\_\\\/']+},
          replace: "",
        },
        {
          desc: "Geminated t after r/i/pa or before rvy -> t",
          search: /(?<=[rfFi]|pa)tt|tt(?=[rvy])\B/,
          replace: "t",
        },
        {
          desc: "Geminated unaspirated consonants after r -> single (medial or initial)",
          search: /\B(?=[rfF]|[rfF]\s)([gjwRdnbmyv])\1\B/,
          replace: [1],
        },
        {
          desc: "Geminated aspirated consonants -> single",
          search: /(j)J|(w)W|(t)T|(d)D/,
          replace: [1, 2, 3, 4],
        },
        {
          desc: "Final ṃ[lśs]|nn -> n",
          search: /M[lSs]|nn\b/,
          replace: "n",
        },
        {
          desc: "Medial nasal following consonant of same class (not yrlv) -> ṃ",
          search: /\B[NYRnm](?=[kKgGcCjJwWqQtTdDpPbB])\B/,
          replace: "M",
        },
        {
          desc: "Final āḥ + voiced -> ā",
          search: /\BAH(?=\s[aAiIuUeEoOgGjJqQdDbBnmyrlv])/,
          replace: "A",
        },
        {
          desc: "Bho[s] variants",
          search: /\bBo[rSzsH]?\b/,
          replace: "BoH",
        },
        {
          desc: "Avagraha cases (like o pi -> aḥ api)",
          search: /\Bo\s(?=[pvsh][aAiIuUeEoO])\b/,
          replace: "aH a",
        },
        {
          desc: "Final aḥ/ar/o + voiced consonants -> aḥ",
          search: /\B(?:a[Hr]|o)(?=\s[gGjJqQdDbBnmyrlv])/,
          replace: "aH",
        },
        {
          desc: "Final aḥ + vowel (except a) -> a",
          search: /\BaH(?=\s[AiIuUfFeEoO])/,
          replace: "a",
        },
        {
          desc: "Final visarga/visarga-like -> ḥ",
          search: /\B(?<=[aAiIuUfFeEoO])H?[rSzs]\b/,
          replace: "H",
        },
        {
          desc: "Medial visarga cases -> ḥ",
          search: /\B(?:(?<=u)z|z(?=k)|s(?=s))\B/,
          replace: "H",
        },
        {
          desc: "Final āv -> au",
          search: /\BAv\b/,
          replace: "O",
        },
        {
          desc: "Final anusvara/anusvara-like (with special cases) -> ṃ",
          search: /\BM?[mN]\b|(?<=k[ai])n(?=\st)|Y(?=\s[jc])/,
          replace: "M",
        },
        {
          desc: "Final c + [ch/ś], Final t + [ś] -> t + ch",
          search: /\B[ct]\s[CS]\B/,
          replace: "t C",
        },
        {
          desc: "Final d + (voiced except n/m/palatal, or absolute final) -> t",
          search: /d(?=(?:\s+[aAiIuUfFeEoOgGqQbByrlv]|$))/,
          replace: "t",
        },
        {
          desc: "Final t + [nm] -> n",
          search: /t(?=\s[nm])/,
          replace: "n",
        },
        {
          desc: "Final j+j, c+c -> t",
          search: /j(?=\sj)|c(?=\sc)/,
          replace: "t",
        },
        {
          desc: "Final e + i -> a",
          search: /e(?=\si)/,
          replace: "a",
        },
        {
          desc: "Final e + i -> a",
          search: /e(?=\si)/,
          replace: "a",
        },
        # {
        #   desc: "Final i + vowel",
        #   search: /i(?=\s[aAuUfFeEoO])/,
        #   replace: "y",
        # },
        # {
        #   desc: "Final u + vowel",
        #   search: /u(?=\s[aAiIfFeEoO])/,
        #   replace: "v",
        # },
        # Invert the two above.
        {
          desc: "Final y + vowel",
          search: /y(?=\s[aAuUfFeEoO])/,
          replace: "i",
        },
        {
          desc: "Final v + vowel",
          search: /v(?=\s[aAiIfFeEoO])/,
          replace: "u",
        },
        {
          desc: "-e[nṇ]okta- -> a_ukta",
          search: /\B(?<=e[nR])o(?=kt)\B/,
          replace: "a_u",
        },
        {
          desc: "-(in|y)okta- -> ā_ukta",
          search: /\B(?<=in|y)o(?=kt)\B/,
          replace: "A_u",
        },
      ]
    )

    module_function

    def normalize_slp1(*lemmata)
      lemmata.map! { |l| l.to_s.strip }
      lemmata.reject!(&:blank?)
      normalize_internal(lemmata)
    end

    def normalize_iast(*lemmata)
      lemmata.map! { |l| Dphil::Transliterate.iast_slp1(l.to_s.strip) }
      lemmata.reject!(&:blank?)
      out = normalize_internal(lemmata)
      out.map! { |l| Dphil::Transliterate.slp1_iast(l) }
      out
    end

    class << self
      private

      def normalize_internal(lemmata)
        lemma_sizes = lemmata.map { |l| l.blank? ? 0 : 1 + l.scan(/\s+/).size }
        lemma = lemmata.join(" ")

        replacements = []
        # STDERR.puts(lemma)
        RULES.each do |rule|
          # STDERR.puts(rule[:desc])
          lemma.gsub!(rule[:search]) do
            if rule[:replace].is_a?(Array)
              replacements << rule[:replace].map { |n| Regexp.last_match[n] }.join("")
            else
              replacements << rule[:replace]
            end
            "\u001A#{replacements.length - 1}\u001A"
          end
          # STDERR.puts(lemma)
        end

        lemma.gsub!(/\u001A(\d+)\u001A/) do
          replacements[Regexp.last_match[1].to_i]
        end

        norm_result = lemma.split(/\s+/)
        # STDERR.puts("#{lemma_sizes.inspect} #{norm_result.inspect}")
        lemma_sizes.map { |ls| norm_result.shift(ls).join(" ").tr("_", " ") }
      end
    end
  end
end