# frozen_string_literal: true
require "active_support/core_ext/object/try"

require "dphil/helpers"
require "dphil/version"
require "dphil/constants"
require "dphil/cache"
require "dphil/logger"

require "dphil/transliterate"
require "dphil/metrical_data"
require "dphil/verse_analysis"

require "dphil/script_string"
require "dphil/lemma"
require "dphil/lemma_list"
require "dphil/tei_xml"
require "dphil/verse"

# Namespace module definition
module Dphil
  using Helpers::Refinements
end
