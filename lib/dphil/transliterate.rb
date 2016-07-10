# frozen_string_literal: true
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
      @default_script = scr
    end

    def transliterate(str, all = false, from: nil, to:)
      from = detect_or_raise(str) if from.nil?
      from.try(:delete, to)
      from = from.try_first
      return str if from == to
      raise "Source script unsupported [:#{from}]" unless support_script?(from)
      raise "Destination script unsupported [:#{to}]" unless support_script?(to)
      public_send("#{from}_#{to}", str, all)
    rescue RuntimeError => e
      Dphil.logger.error "Transliteration Error: #{e}"
      return str
    end

    def support_script?(script)
      Constants::TRANS_SCRIPTS.include?(script)
    end

    def iast_ascii(st, all = false)
      process_string(st, all) do |out|
        unicode_downcase!(out, true)
        out.tr!(Constants::CHARS_IAST, Constants::CHARS_ASCII)
        out
      end
    end

    def iast_kh(st, all = false)
      process_string(st, all) do |out|
        unicode_downcase!(out, true)
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
        unicode_downcase!(out, true)
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

    def detect(str, ignore_control = false)
      str = str.gsub(Constants::TRANS_CTRL_WORD, "") unless ignore_control
      scr_arr = detect_str_type(str, :unique)
      return scr_arr unless scr_arr.nil?

      scr_arr = detect_str_type(str, :shared)
      scr_arr || @default_script
    end

    def normalize_slp1(st)
      out = st.dup
      out.gsub!(Constants::TRANS_CTRL_WORD) do |match|
        control_content = match[Constants::TRANS_CTRL_WORD_CONTENT, 1]
        next match if control_content&.match(Constants::TRANS_CTRL_WORD_PROCESSED)
        "{{##{Digest::SHA1.hexdigest(control_content).rjust(40, '0')}#}}"
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
        return yield str if ignore_control

        scan = str.scan(Constants::TRANS_CTRL_WORD)
        return yield str if scan.empty?
        return str if scan.first == str

        str.gsub!(Constants::TRANS_CTRL_WORD, "\uFFFC")
        str = yield str
        str.gsub!("\uFFFC") { scan.shift }
        str
      end

      def process_string(str, ignore_control = false, &block)
        process_string!(str.dup, ignore_control, &block)
      end

      def detect_str_type(str, type)
        scr_arr = Constants::CHARS_R[type].each_with_object([]) do |(script, regex), memo|
          memo << script if str =~ regex
        end
        scr_arr.length > 1 ? scr_arr : scr_arr.first
      end

      def detect_or_raise(str)
        script = detect(str)
        if script.nil?
          raise("Could not determine encoding for \"#{str}\" and no default specified.")
        elsif script.is_a?(Array)
          warn "Multiple encodings detected for \"#{str}\" #{script.inspect}."
        end
        script
      end
    end
  end
end
