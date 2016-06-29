# frozen_string_literal: true
require "awesome_print"
require "active_support"

require "dphil/version"
require "dphil/constants"
require "dphil/transliterate"
require "dphil/metrical_data"
require "dphil/verse_analysis"
require "dphil/tei_xml"
require "dphil/lemma_list"
require "dphil/lemma"

# Namespace module definition
module Dphil
  module_function

  def cache
    @cache ||= ActiveSupport::Cache::MemoryStore.new
  end
end
