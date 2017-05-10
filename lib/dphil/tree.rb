# frozen_string_literal: true

module Dphil
  class Tree
    attr_reader :nodes, :tree

    def initialize(input)
      if input.respond_to?(:to_str)
        @nodes = nodes_from_lengths(input.to_str)
      elsif input&.key?("nodes")
        @nodes = parse_json_nodes(input["nodes"])
      elsif input.respond_to?(:read)
        @nodes = nodes_from_lengths(input.read)
      else
        raise ArgumentError, 'Input must respond to #to_str, #read, or #["nodes"]'
      end
      @tree = tree_from_nodes(nodes)
      IceNine.deep_freeze(self)
    end

    def to_h
      {
        nodes: nodes,
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

    private

    def parse_json_nodes(json_nodes)
      json_nodes.each_with_object({}) do |(id, node), acc|
        acc[id.to_i] = TreeNode.new(node)
      end
    end

    def nodes_from_lengths(input)
      if input.match?(/^\s*\{.*?(?:'nodes'|"nodes")/m)
        return parse_json_nodes(JSON.parse(input)["nodes"])
      end

      input = input[/Branch lengths and linkages.*?\n\-{40,}\n(.*?)\n\-{40,}\nSum/m, 1]
              &.split("\n")&.map { |l| l.strip.split(/\s{3,}/) }
      raise ArgumentError, "Branch data could not be found in input" if input.nil?

      input.each_with_object({}) do |arr, hash|
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
