# frozen_string_literal: true

module Dphil
  #
  # Mixin module for Linked Data output
  #
  # Requires that a class implements +#as_json+
  #
  module LDOutput
    using Dphil::Refinements::NaturalSort
    # Outputs a Linked Data Hash
    def as_jsonld(**options)
      ld = {
        "@context" => options.delete(:context) || Constants::LD_CONTEXTS[self.class.name],
        "@type" => options.delete(:ld_type) || Constants::LD_TYPES[self.class.name],
      }.merge!(as_json(options))

      ld_expanded = JSON::LD::API.expand(ld)
      return ld_expanded if options[:compact] == false

      ld_compact = JSON::LD::API.compact(ld_expanded, ld["@context"])
      { "@context" => ld_compact.delete("@context") }.merge!(ld_compact.natural_sort_keys)
    end

    def to_jsonld(**options)
      as_jsonld(options).to_json(options)
    end
  end
end
