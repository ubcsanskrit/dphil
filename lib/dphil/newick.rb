# frozen_string_literal: true

require "bio"

module Dphil
  module NewickTree
    module_function

    def tree_from_nex(filename, tree_id: nil, taxa_map: nil) # rubocop:disable MethodLength
      data = File.read(filename).to_s[/^\s*tree MajRule = \[&R\](.*)$/, 1]
      tree = Bio::Newick.new(data).tree
      new_taxa_id = (taxa_map&.keys&.max || 0) + 1
      tree_hsh = tree.nodes.each_with_object({}) do |n, acc|
        next if n == tree.root
        id = taxa_map&.key(n.name)
        if id.nil?
          id = new_taxa_id
          new_taxa_id += 1
        end
        acc[id] = n
      end

      tree_nodes = tree_hsh.each_with_object({}) do |(id, node), acc|
        out = {
          id: id,
          name: node.name || "##{id}",
        }

        parent = tree.parent(node)
        out[:parent] = tree_hsh.key(parent) || 0
        out[:length] = tree.get_edge(node, parent)&.distance

        out[:children] = tree.children(node).map do |n|
          tree_hsh.key(n)
        end
        acc[id] = out
      end

      stats = {
        length: nil,
        ci: nil,
        hi: nil,
        ci_ex: nil,
        hi_ex: nil,
        ri: nil,
        rc: nil,
      }

      Dphil::Tree.new(tree_id, nodes: tree_nodes, stats: stats)
    end
  end
end
