# frozen_string_literal: true
module Dphil
  module Constants
    # Regular expressions for SLP1 syllables
    begin
      vow = "aAiIuUfFxXeEoO"
      con = "kKgGNcCjJYwWqQRtTdDnpPbBmyrlvzSsh"
      add = "MH"

      R_SYL = /[']?[#{con}]*[#{vow}][#{con}#{add}]*(?![#{vow}])\s*/
      R_GVOW = /[AIUFXeEoO]|[MH]$/
      R_GCON = /[#{con}]{2}/
    end

    CHARS_IAST  = "āäaīïiūüuṭḍṅṇñṃśṣḥṛṝḷḹ"
    CHARS_KH    = "AaaIiiUuuTDGNJMzSHṛṝḷḹ"
    CHARS_ASCII = "aaaiiiuuutdnnnmsshrrll"

    CHARS_R_IAST_UNIQ = /[āīūṭḍṅṇñṃśṣḥṛṝḷḹ]/
    CHARS_R_SLP1_UNIQ = /[fFxXwWqQY]/
    CHARS_R_KH_UNIQ = /[AIUTDNJMzSR]/

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

    TRANS_CTRL_WORD = /\{{2}[^\}]*\}{2}/
    TRANS_CTRL_WORD_CONTENT = /\{{2}([^\}]*)\}{2}/
    TRANS_CTRL_WORD_PROCESSED = /#[a-f0-9]{40}#/
  end
end
