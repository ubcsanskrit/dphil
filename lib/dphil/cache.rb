# frozen_string_literal: true
require "active_support/cache"
require "active_support/notifications"

module Dphil
  module_function

  def cache(key, params = nil)
    @cache ||= defined?(::Rails.cache) ? ::Rails.cache : ActiveSupport::Cache::MemoryStore.new(size: 16_384)
    full_key = String.new("Dphil-#{Dphil::VERSION}:cache:#{key}")
    full_key << ":#{Digest::SHA1.base64digest(params.to_s)}" unless params.nil?
    block_given? ? @cache.fetch(full_key, &Proc.new) : @cache.fetch(full_key)
  end
end
