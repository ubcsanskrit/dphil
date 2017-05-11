# frozen_string_literal: true

module Dphil
  #
  # Phylogenetic Tree generated from parsing PAUP output.
  #
  # Immutable.
  #
  class Tree
    attr_reader :nodes, :stats, :tree

    def initialize(input)
      if input.respond_to?(:to_str)
        paup = parse_paup_log(input.to_str)
        @nodes = nodes_from_lengths(paup[:lengths])
        @stats = paup[:stats]
      elsif input&.key?(:nodes) && input&.key?(:stats)
        @nodes = parse_json_nodes(input[:nodes])
        @stats = parse_json_stats(input[:stats])
      else
        raise ArgumentError, "Input must be a String or " \
                             "a Hash with `:nodes` & `:stats` keys."
      end
      @tree = tree_from_nodes(nodes)
      IceNine.deep_freeze(self)
    end

    def to_h
      {
        nodes: nodes,
        stats: stats,
        tree: tree,
      }
    end
    alias as_json to_h

    def to_json(*args)
      as_json.to_json(*args)
    end

    def root
      nodes[tree.id]
    end

    def get_node(id)
      nodes[id]
    end

    def get_parent(node)
      nodes[node.parent]
    end

    def get_children(node)
      node.children&.map { |id| nodes[id] }
    end

    def tree_length
      stats[:length]
    end

    def ci
      stats[:ci]
    end

    private

    PAUP_TREE_STATS = {
      "Tree length" => :length,
      "Consistency index (CI)" => :ci,
      "Homoplasy index (HI)" => :hi,
      "CI excluding uninformative characters" => :ci_ex,
      "HI excluding uninformative characters" => :hi_ex,
      "Retention index (RI)" => :ri,
      "Rescaled consistency index (RC)" => :rc,
    }.freeze

    private_constant :PAUP_TREE_STATS

    def parse_paup_log(input)
      regex = /Branch lengths and linkages.*?\n\-{40,}\n(.*?)\n\-{40,}\n^Sum.*?(^Tree length =.*?)\n\n/m
      match = input.match(regex)&.captures
      raise ArgumentError, "Branch data could not be found in input" if match.nil?

      lengths = match[0]&.split("\n")&.map { |l| l.strip.split(/\s{3,}/) }
      stats = match[1]&.split("\n")&.each_with_object({}) do |l, acc|
        key, val = l.split(" = ")
        acc[PAUP_TREE_STATS[key]] = (val["."] ? val.to_f : val.to_i)
      end

      {
        lengths: lengths,
        stats: stats,
      }
    end

    def parse_json_nodes(json_nodes)
      json_nodes.each_with_object({}) do |(id, node), acc|
        acc[id.to_s.to_i] = TreeNode.new(node)
      end
    end

    def parse_json_stats(json_stats)
      missing_keys = (PAUP_TREE_STATS.values - json_stats.keys)
      raise ArgumentError, "Missing `stats` keys: #{missing_keys}" unless missing_keys.empty?
      json_stats.each_with_object({}) do |(k, v), acc|
        raise ArgumentError, "Stat `#{k}` is not a Numeric" unless v.is_a?(Numeric)
        acc[k] = v
      end
    end

    def nodes_from_lengths(lengths)
      lengths.each_with_object({}) do |arr, hash|
        name, id = arr[0].match(/^(.*?)\s?\(?([0-9]{1,4})\)?$/).captures
        id = id.to_i
        parent = arr[1].to_i
        node = TreeNode.new(
          id: id,
          name: (name.present? ? name : "##{id}"),
          length: arr[2].to_i,
          parent: parent
        )
        hash[id] ||= TreeNode.new
        hash[id].merge!(node)

        next if parent.zero?
        hash[parent] ||= TreeNode.new(
          id: parent,
          name: (parent.to_i.zero? ? parent : "##{parent}"),
          length: 0,
          parent: 0
        )
        hash[parent].children ||= []
        hash[parent].children << id
      end
    end

    def tree_from_nodes(nodes)
      root = nodes.select { |_, node| node.parent.zero? }&.first&.last
      return {} if root.blank?
      append_children(nodes, root)
    end

    def append_children(nodes, node)
      new_node = TreeNode.new(node.to_h)
      return new_node unless new_node.children.present?
      new_node.children = new_node.children.map { |id| append_children(nodes, nodes[id]) }
      new_node
    end
  end
end
