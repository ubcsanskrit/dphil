# frozen_string_literal: true
require "nokogiri"

module Dphil
  # An object containing a list of lemmata generated through SAX parsing of an
  #   XML document.
  # Immutable.
  class LemmaList < ::Nokogiri::XML::SAX::Document
    include Enumerable

    attr_reader :name

    def initialize(source)
      @lemma_ignore_start_tags = Set.new(%w[TEI text body pre post div])
      @lemma_ignore_end_tags = @lemma_ignore_start_tags + Set.new(%w[pb lb])
      @members = []
      source = source.to_s.strip
      return if source.empty?
      @index = 0
      @open_elements = []
      @current_pb = []
      @current_lb = []
      @current_chars = ""
      @current_lemma = []
      @inside_hyphen = false
      @empty_element = true

      @parser = Nokogiri::XML::SAX::Parser.new(self)
      @parser.parse(source)
    end

    def each(&block)
      @members.each(&block)
    end

    def members(limit = nil)
      return members[0, limit] if limit.is_a? Numeric
      members
    end

    def [](*args)
      @members[*args]
    end

    def get(index)
      raise "Non-numeric index passed to Lemma.get" unless index.is_a? Numeric
      if index < 1
        warn "Minimum index of Lemma.get() is 1"
        index = 1
      end
      @members[index - 1]
    end

    def size
      @members.size
    end

    def to_s
      @members.map(&:text).join("\n")
    end

    def cx_tokens
      @members.map do |lemma|
        out = {
          t: lemma.text,
          n: Dphil::Transliterate.normalize_iast(lemma.text),
          i: lemma.index,
          p: lemma.page,
          f: lemma.facs,
          l: lemma.line,
        }
        warn "Token empty: #{out}" if out[:t].empty?
        out
      end
    end

    private

    def start_element(name, attrs = [])
      return if @lemma_ignore_start_tags.include?(name)

      if %w[pb lb].include?(name)
        el = gen_xmlel(name, attrs, true)
        if @current_lemma.empty?
          instance_variable_set("@current_#{name}", [el])
        else
          instance_variable_get("@current_#{name}") << el
        end
      else
        el = gen_xmlel(name, attrs)
        @open_elements << gen_xmlel(name, attrs)
      end

      @empty_element = true
      @current_lemma << el unless el.empty?
    end

    def end_element(name)
      return if @lemma_ignore_end_tags.include?(name)

      if @empty_element
        @current_lemma[-1].gsub!(%r{/*>\z}, "/>")
        @empty_element = false
      else
        @current_lemma << "</#{name}>"
      end
      @open_elements.pop
    end

    def characters(string)
      @empty_element = false
      string.split(/(\s)/).reject(&:empty?).each do |lemma|
        @current_chars += lemma.strip

        if lemma =~ /\-$/
          @inside_hyphen = true
        elsif lemma =~ /^\-?[^\s]/
          @inside_hyphen = false
        end

        if lemma.match(/^\s+$/) && !@inside_hyphen
          finalize
          next
        end

        text = lemma.strip
        @current_lemma << text unless text.empty?
      end
    end

    def end_document
      finalize
      (instance_variables - [:@members]).each do |var|
        remove_instance_variable(var)
      end
    end

    def gen_xmlel(name, attrs, self_closing = false)
      attr_list = attrs.reduce("") do |result, attr|
        %(#{result} #{attr[0]}="#{attr[1].gsub('"', '&quot;')}")
      end
      self_closing ? "<#{name}#{attr_list}/>" : "<#{name}#{attr_list}>"
    end

    def gen_xmlclose(el)
      el.gsub(/^<([^\s\>]+).*/, '</\\1>')
    end

    def append_lemma
      return if @current_chars =~ /[^\s\-\.\|]+/ # if not .empty?
      new_lemma_source = @current_lemma.join("")
      new_lemma = { source: new_lemma_source, index: @index }
      @index += 1
      @members << new_lemma
    end

    def finalize
      return if @current_lemma.empty?
      @current_lemma.unshift(@current_lb.first) unless @current_lemma[0] == @current_lb.first
      @current_lemma.unshift(@current_pb.first) unless @current_lemma[0] == @current_pb.first

      # Make sure missing open or close tags are inserted
      unless @open_elements.empty?
        @current_lemma.concat(@open_elements.reverse.map { |e| gen_xmlclose(e) })
        prime_next = @open_elements.dup
      end

      append_lemma

      @current_pb = [@current_pb.last]
      @current_lb = [@current_lb.last]
      @current_chars = ""
      @current_lemma = prime_next || []
      @inside_hyphen = false
    end
  end
end
