# frozen_string_literal: true
module Dphil
  # Public: A storage object for words and groups of words from TEI XML data.
  # Also contains information about the source/location of the words.
  # Immutable.
  class Lemma
    using ::Ragabash::Refinements
    # Public: Returns the raw source data for the lemma.
    attr_reader :source, :text, :page, :facs, :line, :index

    # Public: Initialize a lemma object.
    #
    # source - XML data to initialize the lemma from
    def initialize(source = "", index = nil)
      @source = source.strip
      @index = index

      xml = Nokogiri::XML("<lemma>#{source}</lemma>") { |config| config.strict.noent }
      xml.encoding = "UTF-8"

      @text = xml.text.strip.gsub(/\-+\s*\-*/, "")
      @page = xml.css("pb").map { |el| el.attr("n") }.join(",")
      @facs = xml.css("pb").map { |el| el.attr("facs") }.join(",")
      @line = xml.css("lb").map { |el| el.attr("n") }.join(",")
    rescue Nokogiri::XML::SyntaxError => e
      $stderr.puts "Error in Lemma.new(`#{source}`, ...): #{e}"
      abort
    end

    def to_s
      "(#{index}|#{page}:#{line}) #{text}"
    end

    def to_sym
      "<Lemma>#{self}".to_sym
    end

    def ==(other)
      return false unless other.is_a?(Dphil::Lemma)
      source == other.source
    end
  end
end
