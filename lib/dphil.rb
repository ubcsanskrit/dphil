# frozen_string_literal: true

require "active_support/inflector"
require "active_support/json"
require "active_support/core_ext/object/json"
require "active_support/core_ext/object/try"
require "active_support/core_ext/hash/indifferent_access"

require "csv"
require "json"
require "json/ld"
require "set"
require "unf"
require "pp"

require "ragabash"

require "dphil/version"
require "dphil/constants"
require "dphil/cache"
require "dphil/logger"
require "dphil/ld_output"

require "dphil/transliterate"
require "dphil/metrical_data"
# require "dphil/verse_analysis"
require "dphil/verse_analysis_new"

require "dphil/syllables"
require "dphil/script_string"
require "dphil/lemma"
require "dphil/lemma_list"
require "dphil/tei_xml"
require "dphil/verse"

require "dphil/paup"
require "dphil/tree"
require "dphil/tree_node"
require "dphil/character"
require "dphil/character_matrix"
require "dphil/change_list"

# Namespace module definition
module Dphil
  Transliterate.default_script = :iast
end
