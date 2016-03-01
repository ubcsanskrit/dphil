# frozen_string_literal: true
module Dphil
  # Transliteration module for basic romanization formats.
  module Transliterate
    @iast_chars  = "āäaīïiūüuṭḍṅṇñṃśṣḥṛṝḷḹ"
    @kh_chars    = "AaaIiiUuuTDGNJMzSHṛṝḷḹ"
    @ascii_chars = "aaaiiiuuutdnnnmsshrrll"

    @iast_kh_comp = {
      "ḹ" => "lRR",
      "ḷ" => "lR",
      "ṝ" => "RR",
      "ṛ" => "R",
    }

    @slp1_match = {
      "A" => "ā",
      "I" => "ī",
      "U" => "ū",
      "f" => "ṛ",
      "F" => "ṝ",
      "x" => "ḷ",
      "X" => "ḹ",
      "E" => "ai",
      "O" => "au",
      "K" => "kh",
      "G" => "gh",
      "C" => "ch",
      "J" => "jh",
      "W" => "ṭh",
      "Q" => "ḍh",
      "T" => "th",
      "D" => "dh",
      "P" => "ph",
      "B" => "bh",
      "w" => "ṭ",
      "q" => "ḍ",
      "N" => "ṅ",
      "Y" => "ñ",
      "R" => "ṇ",
      "S" => "ś",
      "z" => "ṣ",
      "M" => "ṃ",
      "H" => "ḥ",
    }

    @control_word = /\A[{]{2}(.*)[}]{2}\z/
    @control_word_processed = /\A#[0-9a-f]{40}#\z/

    module_function

    def unicode_downcase(st)
      out = st.dup
      out.unicode_normalize!(:nfd)
      out.downcase!
      out.unicode_normalize!(:nfc)
      out
    end

    def iast_ascii(st)
      out = unicode_downcase(st)
      out.tr!(@iast_chars, @ascii_chars)
      out
    end

    def iast_kh(st)
      out = unicode_downcase(st)
      out.tr!(@iast_chars, @kh_chars)
      @iast_kh_comp.each { |k, v| out.gsub!(k, v) }
      out
    end

    def kh_iast(st)
      out = st.dup
      out.tr!(@kh_chars, @iast_chars)
      @iast_kh_comp.each { |k, v| out.gsub!(v, k) }
      out
    end

    def iast_slp1(st)
      out = unicode_downcase(st)
      @slp1_match.each { |k, v| out.gsub!(v, k) }
      out
    end

    def slp1_iast(st)
      out = st.dup
      @slp1_match.each { |k, v| out.gsub!(k, v) }
      out
    end

    def normalize_slp1(word)
      match = word[@control_word, 1]
      if match
        return word if match[@control_word_processed]
        return "{{##{Digest::SHA1.hexdigest(word)}#}}"
      end
      out = word.dup
      out.tr!("b", "v")
      out.gsub!(/\B[NYRnm]/, "M") # Medial and final nasals
      out.gsub!(/\B[Hrs]\b/, "") # Final visarga/r/s
      out
    end

    def normalize_iast(word)
      out = iast_slp1(word)
      normalize_slp1(out)
    end
  end
end
