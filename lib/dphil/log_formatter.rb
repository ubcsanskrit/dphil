# frozen_string_literal: true
require "awesome_print"

module Dphil
  using Helpers::Refinements
  class LogFormatter < ::Logger::Formatter
    def colorize(severity, string)
      color = SEVERITY_MAP[severity] || :none
      "#{COLOR_MAP[color]}#{string}#{COLOR_MAP[:none]}"
    end

    def call(severity, timestamp, progname, msg)
      out = ""
      out += colorize(severity, "[#{timestamp.strftime('%Y-%m-%d %H:%M:%S %Z')}][#{severity}] ")
      out += colorize("PROGNAME", "#{progname}: ") unless progname.nil?
      out + (msg.is_a?(String) ? msg : msg.ai(indent: -2)) + "\n"
    end

    COLOR_MAP = {
      none:   "\e[0m",
      bold:   "\e[1m",
      red:    "\e[31m",
      yellow: "\e[33m",
      green:  "\e[32m",
      cyan:   "\e[36m",
    }.freeze

    SEVERITY_MAP = {
      "ERROR" => :red,
      "FATAL" => :red,
      "WARN" => :yellow,
      "INFO" => :green,
      "DEBUG" => :cyan,
      "PROGNAME" => :bold,
    }.freeze
    private_constant :COLOR_MAP, :SEVERITY_MAP
  end
end
