# frozen_string_literal: true
require "active_support/cache"
require "active_support/notifications"

module Dphil
  using Helpers::Refinements

  module_function

  def cache(key, params = nil)
    @cache ||= defined?(::Rails.cache) ? ::Rails.cache : ActiveSupport::Cache::MemoryStore.new(size: 16_384)
    key = "Dphil-#{Dphil::VERSION}:cache:#{key}"
    case params
    when nil
    when Enumerable
      params.map { |p| key += ":#{Digest::SHA1.base64digest(p.to_s)}" }
    else
      key += Digest::SHA1.base64digest(p.to_s)
    end
    block_given? ? @cache.fetch(key, &Proc.new) : @cache.fetch(key)
  end
end
