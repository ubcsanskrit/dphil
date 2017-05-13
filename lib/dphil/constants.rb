# frozen_string_literal: true

require "set"

module Dphil
  module Constants
    using ::Ragabash::Refinements
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

    # Linked Data types and contexts
    begin
      ld_context_global = {
        "@version" => 1.1,
        "oa" => "http://www.w3.org/ns/oa#",
        "dc" => "http://purl.org/dc/elements/1.1/",
        "xsd" => "http://www.w3.org/2001/XMLSchema#",
        "ubcs" => "http://ld.ubcsanskrit.ca/api#",
        "id" => { "@id" => "dc:identifier" },
      }

      ld_context_character = {
        "states" => { "@id" => "ubcs:charStateBySymbol", "@container" => "@index" },
        "symbols" => { "@id" => "ubcs:charSymbolByState", "@container" => "@index" },
        "stateTotals" => { "@id" => "ubcs:charStateTotalsByState", "@container" => "@index" },
        "state_totals" => { "@id" => "ubcs:charStateTotalsByState", "@container" => "@index" },
        "taxaStates" => { "@id" => "ubcs:charStateByTaxon", "@container" => "@index" },
        "taxa_states" => { "@id" => "ubcs:charStateByTaxon", "@container" => "@index" },
        "statesTaxa" => { "@id" => "ubcs:taxonByCharState", "@container" => "@index" },
        "states_taxa" => { "@id" => "ubcs:taxonByCharState", "@container" => "@index" },
        "isInformative" => { "@id" => "ubcs:charStateIsInformative", "@type" => "xsd:boolean" },
        "is_informative" => { "@id" => "ubcs:charStateIsInformative", "@type" => "xsd:boolean" },
        "isConstant" => { "@id" => "ubcs:charStateIsConstant", "@type" => "xsd:boolean" },
        "is_constant" => { "@id" => "ubcs:charStateIsConstant", "@type" => "xsd:boolean" },
      }

      ld_context_matrix = {
        "taxaNames" => { "@id" => "dc:identifier", "@container" => "@index" },
        "taxa_names" => { "@id" => "dc:identifier", "@container" => "@index" },
        "characters" => {
          "@id" => "ubcs:phyloCharacter",
          "@container" => "@index",
          "@context" => ld_context_character,
        },
      }

      LD_TYPES = {
        "Dphil::Character" => "ubcs:phyloCharacter",
        "Dphil::CharacterMatrix" => "ubcs:characterMatrix",
      }.deep_freeze

      LD_CONTEXTS = {
        "Dphil::Character" => ld_context_global.merge(ld_context_character),
        "Dphil::CharacterMatrix" => ld_context_global.merge(ld_context_matrix),
      }.deep_freeze
    end
  end
end
