# frozen_string_literal: true

module Dphil
  class TeiXML
    using Dphil::Refinements
    # Public: Initialize a TeiXML object
    #
    def initialize(source)
      source = %(<TEI version="5.0" xmlns="http://www.tei-c.org/ns/1.0"></TEI>) if source.strip.empty?
      @raw_xml = source
    end

    # Return or re-parse xml
    def xml
      @xml ||=
        begin
          xml = Nokogiri::XML(@raw_xml) { |config| config.strict.noent }
          xml.encoding = "UTF-8"
          xml.remove_namespaces!
          xml_normalize!(xml)
        rescue Nokogiri::XML::SyntaxError => e
          raise "TEIDocument (source: #{@raw_xml}) caught exception: #{e}"
        end
    end

    def to_xml
      xml.to_xml
    end

    alias to_s to_xml

    def empty?
      xml.xpath("//text()[normalize-space()]").empty?
    end

    # Public: Return a portion of the document as a new document
    #
    # expr - a CSS selector or XPath expression
    #
    # Returns a new document.
    def crop(expr)
      segment = xml.search(expr)
      pb = page_of(segment)
      lb = line_of(segment)

      source = <<~TEIDOC
        <TEI version="5.0" xmlns="http://www.tei-c.org/ns/1.0">
          <pre>#{pb&.to_xml}#{lb&.to_xml}</pre>
          #{segment.to_xml}
          <post></post>
        </TEI>
      TEIDOC
      self.class.new(source)
    end

    def crop_each(expr)
      xml.search(expr).map do |segment|
        pb = page_of(segment)
        lb = line_of(segment)

        source = <<~TEIDOC
          <TEI version="5.0" xmlns="http://www.tei-c.org/ns/1.0">
            <pre>#{pb&.to_xml}#{lb&.to_xml}</pre>
            #{segment.to_xml}
            <post></post>
          </TEI>
        TEIDOC
        self.class.new(source)
      end
    end

    # Public: Remove elements from the document based on CSS selector.
    #
    # expr - a CSS selector or XPath expression
    #
    # Returns a new document.
    def reject(expr)
      source = xml.dup
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
      source = xml.dup
      subst_text = subst_text.to_s.gsub(/\s+/, "_") unless subst_text.nil?

      source.search(expr).each do |node|
        set = Nokogiri::XML::NodeSet.new(source)
        escaped_text = ":#{node.attribute('id').to_s.gsub(/\s+/, '_').tr('-.', '–·')}"
        text_content = "#{subst_text || node.name}#{escaped_text}"
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
    def xml_normalize!(doc)
      doc.search("//text()").each do |text_node|
        text_node.content = text_node.content.gsub(%r{\s+[\s\.\-\\\/\_]*}, " ")
      end

      # Remove empty modification tags.
      doc.search(
        "//add[not(node())]|" \
        "//del[not(node())]|" \
        "//mod[not(node())]|" \
        "//unclear[not(node())]|" \
        "//g[not(node())]"
      ).remove
      doc
    end
  end
end
