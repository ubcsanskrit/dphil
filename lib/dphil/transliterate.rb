# frozen_string_literal: true
require "sanscript"

module Dphil
  # Transliteration module for basic romanization formats.
  module Transliterate
    using Helpers::Refinements
    @default_script = nil

    module_function

    def default_script
      @default_script
    end

    def default_script=(scr)
      scr = scr.to_sym
      if script_supported?(scr)
        @default_script = scr
      else
        warn "Script unsupported [:#{scr}]"
      end
    end

    def transliterate(str, first, second = nil)
      Sanscript.transliterate(str, first, second, default_script: default_script)
    rescue RuntimeError => e
      Dphil.logger.error "Transliteration Error: #{e}"
      return str
    end

    def script_supported?(script)
      Sanscript::Transliterate.scheme_names.include?(script)
    end

    def to_ascii(str)
      process_string(str) do |out|
        out.unicode_normalize!(:nfd)
        out.gsub!(/[^\u0000-\u007F]+/, "")
        out
      end
    end

    def iast_kh(str)
      transliterate(str, :iast, :kh)
    end

    def kh_iast(str)
      transliterate(str, :kh, :iast)
    end

    def iast_slp1(str)
      transliterate(str, :iast, :slp1)
    end

    def slp1_iast(str)
      transliterate(str, :slp1, :iast)
    end

    def detect(str)
      Sanscript::Detect.detect_scheme(str)
    end

    def normalize_slp1(st)
      out = st.dup
      out.gsub!(Constants::TRANS_CTRL_WORD) do |match|
        control_content = match[Constants::TRANS_CTRL_WORD_CONTENT, 1]
        next match if control_content&.match(Constants::TRANS_CTRL_WORD_PROCESSED)
        "{###{Digest::SHA1.hexdigest(control_content).rjust(40, '0')}##}"
      end

      process_string!(out) do |token|
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

    def unicode_downcase!(str, ignore_control = false)
      return UNICODE_DOWNCASE_PROC.call(str) if ignore_control
      process_string!(str, &UNICODE_DOWNCASE_PROC)
    end

    def unicode_downcase(st, ignore_control = false)
      unicode_downcase!(st.dup, ignore_control)
    end

    UNICODE_DOWNCASE_PROC = lambda do |str|
      str.unicode_normalize!(:nfd)
      str.downcase!
      str.unicode_normalize!(:nfc)
      str
    end

    private_constant :UNICODE_DOWNCASE_PROC

    class << self
      alias t transliterate

      private

      def process_string!(str, ignore_control = false, &_block)
        str = str.to_str
        return yield str if ignore_control

        scan = str.scan(Constants::TRANS_CTRL_WORD)
        return yield str if scan.empty?
        return str if scan.first == str

        str.gsub!(Constants::TRANS_CTRL_WORD, "\u0026\u0026")
        str = yield str
        str.gsub!("\u0026\u0026") { scan.shift }
        str
      end

      def process_string(str, ignore_control = false, &block)
        process_string!(str.dup, ignore_control, &block)
      end
    end
  end
end
