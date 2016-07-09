# frozen_string_literal: true
module Dphil
  # Transliteration module for basic romanization formats.
  module Transliterate
    module_function

    def iast_ascii(st, all = false)
      process_string(st, all) do |out|
        out = unicode_downcase(out, true)
        out.tr!(Constants::CHARS_IAST, Constants::CHARS_ASCII)
        out
      end
    end

    def iast_kh(st, all = false)
      process_string(st, all) do |out|
        out = unicode_downcase(out, true)
        out.tr!(Constants::CHARS_IAST, Constants::CHARS_KH)
        Constants::CHARS_COMP_IAST_KH.each { |k, v| out.gsub!(k, v) }
        out
      end
    end

    def kh_iast(st, all = false)
      process_string(st, all) do |out|
        out.tr!(Constants::CHARS_KH, Constants::CHARS_IAST)
        Constants::CHARS_COMP_IAST_KH.each { |k, v| out.gsub!(v, k) }
        out
      end
    end

    def iast_slp1(st, all = false)
      process_string(st, all) do |out|
        out = unicode_downcase(out, true)
        Constants::CHARS_SLP1_IAST.each { |k, v| out.gsub!(v, k) }
        out
      end
    end

    def slp1_iast(st, all = false)
      process_string(st, all) do |out|
        Constants::CHARS_SLP1_IAST.each { |k, v| out.gsub!(k, v) }
        out
      end
    end

    def detect(st)
      st = unicode_downcase(st.dup)
      return :iast if Constants::CHARS_R_IAST_UNIQ.match(st)
      return :slp1 if Constants::CHARS_R_SLP1_UNIQ.match(st)
      return :kh if Constants::CHARS_R_KH_UNIQ.match(st)
    end

    def normalize_slp1(st)
      out = st.dup
      out.gsub!(Constants::TRANS_CTRL_WORD) do |match|
        control_content = match[Constants::TRANS_CTRL_WORD_CONTENT, 1]
        next match if control_content&.match(Constants::TRANS_CTRL_WORD_PROCESSED)
        "{{##{Digest::SHA1.hexdigest(control_content).rjust(40, '0')}#}}"
      end

      process_string(out, false) do |token|
        token.tr!("b", "v")
        token.gsub!(/['‘]\b/, "") # Avagraha
        token.gsub!(/\B[NYRnm]/, "M") # Medial and final nasals
        token.gsub!(/\B[Hrs]\b/, "") # Final visarga/r/s
        token.gsub!(%r{[\.\-\_\\\/]}, "") # Punctuation
        token
      end
    end

    def normalize_iast(word)
      out = iast_slp1(word)
      normalize_slp1(out)
    end

    def unicode_downcase!(st, ignore_control = false)
      return UNICODE_DOWNCASE_PROC.call(st) if ignore_control
      process_string!(st, &UNICODE_DOWNCASE_PROC)
    end

    def unicode_downcase(st, ignore_control = false)
      unicode_downcase!(st.dup, ignore_control)
    end

    UNICODE_DOWNCASE_PROC = lambda do |st|
      st.unicode_normalize!(:nfd)
      st.downcase!
      st.unicode_normalize!(:nfc)
      st
    end

    private_constant :UNICODE_DOWNCASE_PROC

    class << self
      private

      def process_string!(st, ignore_control = false, &_block)
        return yield st if ignore_control

        scan = st.scan(Constants::TRANS_CTRL_WORD)
        return yield st if scan.empty?
        return st if scan[0] == st

        st.gsub!(Constants::TRANS_CTRL_WORD, "\uFFFC")
        st = yield st
        st.gsub!("\uFFFC") { scan.shift }
        st
      end

      def process_string(st, ignore_control = false, &block)
        process_string!(st.dup, ignore_control, &block)
      end
    end
  end
end
