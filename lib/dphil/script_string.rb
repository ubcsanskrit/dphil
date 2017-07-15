# frozen_string_literal: true

require "forwardable"

module Dphil
  class ScriptString
    using ::Ragabash::Refinements
    extend Forwardable
    def_delegators :@string, :<=>, :==, :===, :to_s, :to_str, :empty?, :length
    attr_reader :string

    def initialize(str, script = nil)
      raise "Source must be a String" unless str.respond_to?(:to_str)
      str = str.to_str
      str = str.dup if str.frozen?
      @string = str.encode!(Encoding::UTF_8)
      self.script = script || self.script
    end

    def script
      @script ||= Transliterate.detect(@string)
    end

    def script=(script)
      @script = script.try(:flat_map, &:to_sym) || script.to_sym
    end

    def transliterate(target)
      target = target.to_sym
      string = Transliterate.transliterate(@string, from: @script, to: target)
      if @script.is_a?(Array)
        new_target = @script.dup
        new_target[0] = target
        new_target.uniq!
        target = new_target
      end
      self.class.new(string, target)
    end

    def transliterate!(target)
      target = target.to_sym
      @string = Transliterate.transliterate(@string, from: @script, to: target)
      if @script.is_a?(Array)
        @script[0] = target
        @script.uniq!
      end
      @string
    end

    # String methods implemented to return ScString intances wherever possible

    def downcase
      self.class.new(Transliterate.unicode_downcase(@string), @script)
    end

    def downcase!
      ret_val = Transliterate.unicode_downcase!(@string)
      self unless ret_val.nil?
    end

    def inspect
      "#{@string.inspect}:#{script}"
    end

    def gsub(pattern, rep_hash = nil)
      ret_val = if block_given?
                  @string.gsub(pattern, &Proc.new)
                elsif !rep_hash.nil?
                  @string.gsub(pattern, rep_hash)
                else
                  @string.gsub(pattern)
                end
      return ret_val if ret_val.is_a?(Enumerator)
      self.class.new(ret_val, @script)
    end

    def gsub!(pattern, rep_hash = nil)
      ret_val = if block_given?
                  @string.gsub!(pattern, &Proc.new)
                elsif !rep_hash.nil?
                  @string.gsub!(pattern, rep_hash)
                else
                  @string.gsub!(pattern)
                end
      return ret_val if ret_val.is_a?(Enumerator)
      self unless ret_val.nil?
    end

    def scan(pattern)
      ret_val = if block_given?
                  @string.scan(pattern, &Proc.new)
                else
                  @string.scan(pattern)
                end
      return self if ret_val == @string
      ret_val.map do |match|
        next self.class.new(match, @script) if match.is_a?(String)
        match.map do |group|
          self.class.new(group, @script)
        end
      end
    end

    def slice(a, b = nil)
      slice = b.nil? ? @string.slice(a) : @string.slice(a, b)
      self.class.new(slice, @script)
    end
    alias [] slice

    def slice!(a, b = nil)
      slice = b.nil? ? @string.slice!(a) : @string.slice!(a, b)
      self.class.new(slice, @script)
    end

    def strip
      self.class.new(@string.strip, @script)
    end

    def strip!
      ret_val = @string.strip!
      self unless ret_val.nil?
    end
  end
end
