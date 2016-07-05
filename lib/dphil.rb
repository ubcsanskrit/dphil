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

  def cache(key, *params)
    @cache ||= defined?(::Rails) ? ::Rails.cache : ActiveSupport::Cache::MemoryStore.new(size: 16_384)
    key = "Dphil::cache.#{key}"
    params&.each { |p| key += ".#{Digest::SHA1.base64digest(p.to_s)}" }
    block_given? ? @cache.fetch(key, &Proc.new) : @cache.fetch(key)
  end
end
