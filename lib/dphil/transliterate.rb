# frozen_string_literal: true
module Dphil
  # Transliteration module for basic romanization formats.
  module Transliterate
    @iast_chars  = "ĀāÄäAaĪīÏïIiŪūÜüUuṛḷṬṭḌḍṄṅṆṇÑñṂṃŚśṢṣḤḥ".unicode_normalize(:nfkc).freeze
    @kh_chars    = "AAaaaaIIiiiiUUuuuuRLTTDDGGNNJJMMzzSSHH".unicode_normalize(:nfkc).freeze
    @ascii_chars = "aaaaaaiiiiiiuuuuuurlttddnnnnnnmmsssshh".unicode_normalize(:nfkc).freeze

    @slp1_match = {
      "A" => "ā",
      "I" => "ī",
      "U" => "ū",
      "f" => "ṛ",
      "F" => "ṝ",
      "x" => "ḷ",
      "X" => "ḹ",
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
      "H" => "ḥ"
    }

    @slp1_match.keys.each do |k|
      @slp1_match[k] = @slp1_match[k].unicode_normalize(:nfkc)
    end

    @control_match = /\{\{.*\}\}/

    def self.iast_ascii(st)
      out = st.dup
      out.tr!(@iast_chars, @ascii_chars)
      out
    end

    def self.iast_kh(st)
      out = st.downcase.unicode_normalize(:nfkc)
      out.tr!(@iast_chars, @kh_chars)
      out
    end

    def self.kh_iast(st)
      out = st.dup
      out.tr!(@kh_chars, @iast_chars)
      out
    end

    def self.iast_slp1(st)
      out = st.downcase.unicode_normalize(:nfkc)
      @slp1_match.each do |k, v|
        out.gsub!(v, k)
      end
      out
    end

    def self.slp1_iast(st)
      out = st.dup
      @slp1_match.each do |k, v|
        out.gsub!(k, v)
      end
      out
    end

    def self.normalize_slp1(word)
      return Digest::SHA1.hexdigest(word) if @control_match.match(word)
      out = word.dup
      out.tr!("b", "v") # b->v
      out.gsub!(/\B[NYRnm]/, "M") # Medial and final nasals
      out.gsub!(/\B[Hrs]\z/, "") # Final visarga/r/s
      out
    end

    def self.normalize_iast(word)
      out = iast_slp1(word)
      normalize_slp1(out)
    end
  end
end
