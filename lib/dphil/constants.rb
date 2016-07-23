# frozen_string_literal: true
require "set"

module Dphil
  using ::Ragabash::Refinements
  module Constants
    DEBUG = if defined?(::Rails) && ::Rails.env[/^dev/]
              true
            elsif !ENV["RUBY_ENV"].nil? && ENV["RUBY_ENV"][/^dev/]
              true
            else
              false
            end

    # Regular expressions for SLP1 syllables
    begin
      vow = "aAiIuUfFxXeEoO"
      con = "kKgGNcCjJYwWqQRtTdDnpPbBmyrlvzSsh"
      add = "MH"

      R_SYL = /[']?[#{con}]*[\s]*[#{vow}][#{con}#{add}]*(?![#{vow}])\s*/
      R_GSYL = /[AIUFXeEoO]|[MH]$/
      R_CCONF = /[#{con}]{2}$/
      R_CCON = /[#{con}]{2}/
    end

    TRANS_CTRL_WORD = /\{#.*?#\}/
    TRANS_CTRL_WORD_CONTENT = /\{#(.*?)#\}/
    TRANS_CTRL_WORD_PROCESSED = /#[a-f0-9]{40}#/
  end
end
