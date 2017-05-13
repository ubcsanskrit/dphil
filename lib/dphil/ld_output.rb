# frozen_string_literal: true

module Dphil
  #
  # Mixin module for Linked Data output
  #
  # Requires that a class implements +to_h+
  #
  module LDOutput
    # Outputs a Linked Data Hash
    def as_jsonld(camelize: true, compact: true, **options)
      data = to_h
      data = camelize_symbol_keys(data) if camelize
      data = data.as_json(options)
      return data if options[:data_only]

      ld = {
        "@context" => options[:context] || Constants::LD_CONTEXTS[self.class.name],
        "@type" => options[:ld_type] || Constants::LD_TYPES[self.class.name],
      }.merge!(data)
      ld_expanded = JSON::LD::API.expand(ld)

      return ld_expanded unless compact
      JSON::LD::API.compact(ld_expanded, ld["@context"])
    end

    def to_jsonld(*args)
      as_jsonld(*args).to_json(*args)
    end

    private

    def camelize_symbol_keys(hash)
      hash.deep_transform_keys do |k|
        next k unless k.is_a?(Symbol)
        @@camel_cache[k] ||= k.to_s.camelize(:lower).freeze
      end
    end

    @@camel_cache = {} # rubocop:disable ClassVars
  end
end
