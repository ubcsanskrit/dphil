# frozen_string_literal: true
require "set"

module Dphil
  using Helpers::Refinements
  module Constants
    DEBUG = if defined?(::Rails) && ::Rails.env[/^(test|dev)/]
              true
            elsif !ENV["RUBY_ENV"].nil? && ENV["RUBY_ENV"][/^(test|dev)/]
              true
            else
              false
            end

    TRANS_SCRIPTS = Set.new(%i[deva iast slp1 kh ascii]).freeze

    # Regular expressions for SLP1 syllables
    begin
      vow = "aAiIuUfFxXeEoO"
      con = "kKgGNcCjJYwWqQRtTdDnpPbBmyrlvzSsh"
      add = "MH"

      R_SYL = /[']?[#{con}]*[\s]*[#{vow}][#{con}#{add}]*(?![#{vow}])\s*/
      R_GSYL = /[AIUFXeEoO]|[MH]$|[#{con}]{2}$/
      R_CCON = /[#{con}]{2}/
    end

    CHARS_IAST  = "āäaīïiūüuṭḍṅṇñṃśṣḥṛṝḷḹ"
    CHARS_KH    = "AaaIiiUuuTDGNJMzSHṛṝḷḹ"
    CHARS_ASCII = "aaaiiiuuutdnnnmsshrrll"

    CHARS_R = {
      unique: {
        deva: /\p{Devanagari}/,
        iast: /[āīūṭḍṅṇñṃśṣḥṛṝḷḹĀĪŪṬḌṄṆÑṂŚṢḤṚṜḶḸ]/,
        slp1: /[fFxXwWqQ]/,
      },
      shared: {
        slp1: /[EOY]/, # Allowed in IAST as capital e, o, ya
        kh: /[AIUTDNJMzSR]/, # Allowed in IAST as capital or SLP1 as various.
      },
    }.freeze

    CHARS_COMP_IAST_KH = {
      "ḹ" => "lRR",
      "ḷ" => "lR",
      "ṝ" => "RR",
      "ṛ" => "R",
    }.freeze

    CHARS_SLP1_IAST = {
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
    }.freeze

    TRANS_CTRL_WORD = /\{#.*?#\}/
    TRANS_CTRL_WORD_CONTENT = /\{#(.*?)#\}/
    TRANS_CTRL_WORD_PROCESSED = /#[a-f0-9]{40}#/
  end
end
