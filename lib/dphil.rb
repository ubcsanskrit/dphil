# frozen_string_literal: true
require "awesome_print"
require "active_support"
require "ice_nine"
require 'ice_nine/core_ext/object'

require "dphil/version"
require "dphil/constants"
require "dphil/log_formatter"
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

  def logger
    @logger ||= begin
      if defined?(::Rails)
        ::Rails.logger
      else
        file_logger = ActiveSupport::Logger.new(File.join(GEM_ROOT, "dphil.log"))
        file_logger.formatter = LogFormatter.new
        if Constants::DEBUG
          logger = ActiveSupport::Logger.new(STDERR)
          logger.formatter = file_logger.formatter
          file_logger.extend(ActiveSupport::Logger.broadcast(logger))
        end
        file_logger
      end
    end
  end
end
