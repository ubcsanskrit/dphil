# frozen_string_literal: true

module Dphil
  #
  # PAUP* Log Processor
  #
  module PAUP
    def self.parse_trees(infile)
      infile = File.expand_path(infile)
      return STDERR.puts("File #{infile} not found.") unless File.exist?(infile)

      data = File.read(infile).to_s.split(/^Tree ([0-9]+)\:$/)
      return data if data.empty?

      hash = { preamble: data.shift.strip }

      trees = {}
      data.each_slice(2) do |k, v|
        next trees[:remainder] = k if v.nil?
        branches = v.match(BRANCH_REGEXP)&.captures
        changes = v.match(CHGLIST_REGEXP)&.captures
        arr = []
        arr.concat(%i[lengths stats].zip(branches)) unless branches.nil?
        arr << [:changes, changes[0]] unless branches.nil?
        trees[k.to_i] = arr.to_h
      end

      hash.merge(trees)
    end

    BRANCH_REGEXP = /^Branch lengths and linkages.*?\n\-{40,}\n(.*?)\n\-{40,}\n^Sum.*?(^Tree length =.*?)\n\n/m
    CHGLIST_REGEXP = /^Character change lists:.*?\n\-{40,}\n(.*?)\n\n/m
  end
end
