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
        "isInformative" => { "@id" => "ubcs:charStateIsInformative" },
        "is_informative" => { "@id" => "ubcs:charStateIsInformative" },
        "isConstant" => { "@id" => "ubcs:charStateIsConstant" },
        "is_constant" => { "@id" => "ubcs:charStateIsConstant" },
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

      ld_context_tree_node = {
        "name" => { "@id" => "ubcs:treeNodeName" },
        "length" => { "@id" => "ubcs:branchLength" },
        "parent" => { "@id" => "ubcs:treeNodeParent" },
        "children" => { "@id" => "ubcs:treeNodeChildren" },
      }

      ld_context_tree = {
        "nodes" => {
          "@id" => "ubcs:treeNode",
          "@container" => "@index",
          "@context" => ld_context_tree_node,
        },
        "stats" => {
          "@id" => "ubcs:treeStats",
          "@context" => {
            "ci" => { "@id" => "ubcs:treeCI" },
            "ciEx" => { "@id" => "ubcs:treeCIEx" },
            "ci_ex" => { "@id" => "ubcs:treeCIEx" },
            "hi" => { "@id" => "ubcs:treeHI" },
            "hiEx" => { "@id" => "ubcs:treeHIEx" },
            "hi_ex" => { "@id" => "ubcs:treeHIEx" },
            "length" => { "@id" => "ubcs:treeLengh" },
            "rc" => { "@id" => "ubcs:treeRC" },
            "ri" => { "@id" => "ubcs:treeRI" },
          },
        },
      }

      LD_TYPES = {
        "Dphil::Character" => "ubcs:phyloCharacter",
        "Dphil::CharacterMatrix" => "ubcs:characterMatrix",
        "Dphil::TreeNode" => "ubcs:treeNode",
        "Dphil::Tree" => "ubcs:tree",
      }.deep_freeze

      LD_CONTEXTS = {
        "Dphil::Character" => ld_context_global.merge(ld_context_character),
        "Dphil::CharacterMatrix" => ld_context_global.merge(ld_context_matrix),
        "Dphil::TreeNode" => ld_context_global.merge(ld_context_tree_node),
        "Dphil::Tree" => ld_context_global.merge(ld_context_tree),
      }.deep_freeze
    end
  end
end
