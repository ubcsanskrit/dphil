# frozen_string_literal: true

module Dphil
  #
  # Phylogenetic Tree generated from parsing PAUP output.
  #
  # Immutable.
  #
  class Tree
    include LDOutput
    attr_reader :id, :nodes, :stats, :tree

    def initialize(id = nil, lengths = nil, stats = nil, **opts)
      @id = (opts[:id] || id).to_i
      if lengths.respond_to?(:to_str) && stats.respond_to?(:to_str)
        @nodes = nodes_from_lengths(parse_paup_lengths(lengths))
        @stats = parse_paup_stats(stats)
      elsif (opts.keys & %i[nodes stats]).length == 2
        @nodes = parse_json_nodes(opts[:nodes])
        @stats = parse_json_stats(opts[:stats])
      end
      @tree = tree_from_nodes(nodes)
      IceNine.deep_freeze(self)
    end

    def to_h
      {
        id: id,
        root_id: tree.id,
        nodes: nodes,
        stats: stats,
      }
    end

    def as_json(options = nil)
      to_h.as_json(options)
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

    def parse_paup_lengths(lengths)
      lengths.to_s&.split("\n")&.map { |l| l.strip.split(/\s{3,}/) }
    end

    def parse_paup_stats(stats)
      stats.to_s&.split("\n")&.each_with_object({}) do |l, acc|
        key, val = l.split(" = ")
        acc[PAUP_TREE_STATS[key]] = (val["."] ? val.to_f : val.to_i)
      end
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
        raise ArgumentError, "Stat `#{k}` is not a Numeric" unless v.is_a?(Numeric) || v.nil?
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
