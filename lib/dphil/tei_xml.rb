# frozen_string_literal: true
module Dphil
  class TeiXML
    # Public: Initialize a TeiXML object
    #
    def initialize(source)
      @xml = Nokogiri::XML(source) { |config| config.strict.noent }
      @xml.encoding = "UTF-8"
      @xml.remove_namespaces!
      xml_normalize!

      @empty = true if @xml.xpath("//text()[normalize-space()]").empty?


    rescue Nokogiri::XML::SyntaxError => e
      raise "TEIDocument (source: #{source}) caught exception: #{e}"
    end

    def to_xml
      @xml.to_xml
    end

    alias to_s to_xml

    def empty?
      @empty?
    end

    # Public: Return a portion of the document as a new document
    #
    # expr - a CSS selector or XPath expression
    #
    # Returns a new document.
    def crop(expr)
      segment = @xml.search(expr)
      pb = page_of(segment)
      lb = line_of(segment)

      source = <<EOS
<TEI version="5.0" xmlns="http://www.tei-c.org/ns/1.0">
  <pre>#{pb.to_xml unless pb.nil?}#{lb.to_xml unless lb.nil?}</pre>
  #{segment.to_xml}
  <post></post>
</TEI>
EOS
      self.class.new(source)
    end

    # Public: Remove elements from the document based on CSS selector.
    #
    # expr - a CSS selector or XPath expression
    #
    # Returns a new document.
    def reject(expr)
      source = @xml.dup
      source.search(expr).each do |node|
        node.replace(node.search("pb, lb"))
      end
      self.class.new(source.to_xml)
    end

    # Public: Substitute elements from the document based on CSS selector with
    #   ID-based token text-nodes.
    #
    # expr - a CSS selector or XPath expression
    # subst_text - an optional text identifier
    #
    # Returns a new document.
    def subst(expr, subst_text = nil)
      source = @xml.dup
      subst_text = subst_text.to_s.gsub(/\s+/, "_") unless subst_text.nil?

      source.search(expr).each do |node|
        set = Nokogiri::XML::NodeSet.new(source)
        text_content = "#{subst_text || node.name}:#{node.attribute('id').to_s.gsub(/\s+/, '_').tr('-.', '‑·')}"
        set << Nokogiri::XML::Text.new(" {{#{text_content}}} ", source)
        node.replace(set + node.search("pb, lb"))
      end
      self.class.new(source.to_xml)
    end

    private

    # Get nearest prior <pb/> node.
    #
    # id - node in document to start search from.
    #
    # Returns an XML node.
    def page_of(node)
      node.xpath("preceding::*[name() = 'pb'][1]")
    end

    # Get nearest prior <lb/> node with everything in between.
    #
    # node - node in document to start search from.
    #
    # Returns an XML node.
    def line_of(node)
      node.xpath("preceding::*[name() = 'lb'][1]")
    end

    # Normalize (mostly) whitespace in the XML.
    def xml_normalize!
      @xml.search("//text()").each do |text_node|
        # Remove empty/all-whitespace text nodes

        text_node.content = text_node.content
                                     .gsub(%r{[/\\\|\,\?\.]}, "") # Remove useless punctuation
                                     .gsub(/\s+/, " ") # Compact whitespace
      end

      # Remove empty modification tags.
      @xml.search(
        "//add[not(node())]|" \
        "//del[not(node())]|" \
        "//mod[not(node())]|" \
        "//unclear[not(node())]|" \
        "//g[not(node())]"
      ).remove
      self
    end
  end
end
