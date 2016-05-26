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

    CTRL_WORD = /\{{2}[^\}]*\}{2}/
    CTRL_WORD_CONTENT = /\{{2}([^\}]*)\}{2}/
    CTRL_WORD_PROCESSED = /#[a-f0-9]{40}#/

    private_class_method

    def self.process_string(st, all = false)
      return yield st.dup if all

      scan = st.scan(CTRL_WORD)
      return yield st.dup if scan.empty?
      return st if scan[0] == st

      out = st.dup
      out.gsub!(CTRL_WORD, "\uFFFC")
      out = yield out
      out.gsub!("\uFFFC") do
        scan.shift
      end
      out
    end

    module_function

    def unicode_downcase(st, all = false)
      process_string(st, all) do |out|
        out.unicode_normalize!(:nfd)
        out.downcase!
        out.unicode_normalize!(:nfc)
      end
    end

    def iast_ascii(st, all = false)
      process_string(st, all) do |out|
        out = unicode_downcase(out, true)
        out.tr!(@iast_chars, @ascii_chars)
        out
      end
    end

    def iast_kh(st, all = false)
      process_string(st, all) do |out|
        out = unicode_downcase(out, true)
        out.tr!(@iast_chars, @kh_chars)
        @iast_kh_comp.each { |k, v| out.gsub!(k, v) }
        out
      end
    end

    def kh_iast(st, all = false)
      process_string(st, all) do |out|
        out.tr!(@kh_chars, @iast_chars)
        @iast_kh_comp.each { |k, v| out.gsub!(v, k) }
        out
      end
    end

    def iast_slp1(st, all = false)
      process_string(st, all) do |out|
        out = unicode_downcase(out, true)
        @slp1_match.each { |k, v| out.gsub!(v, k) }
        out
      end
    end

    def slp1_iast(st, all = false)
      process_string(st, all) do |out|
        @slp1_match.each { |k, v| out.gsub!(k, v) }
        out
      end
    end

    def normalize_slp1(st)
      out = st.dup
      out.gsub!(CTRL_WORD) do |match|
        control_content = match[CTRL_WORD_CONTENT, 1]
        next match if control_content&.match(CTRL_WORD_PROCESSED)
        "{{##{Digest::SHA1.hexdigest(control_content).rjust(40, '0')}#}}"
      end

      process_string(out, false) do |token|
        token.tr!("b", "v")
        token.gsub!(/\B[NYRnm]/, "M") # Medial and final nasals
        token.gsub!(/\B[Hrs]\b/, "") # Final visarga/r/s
        token.gsub!(/[\.\-\_]/, "") # Punctuation
        token
      end
    end

    def normalize_iast(word)
      out = iast_slp1(word)
      normalize_slp1(out)
    end
  end
end
