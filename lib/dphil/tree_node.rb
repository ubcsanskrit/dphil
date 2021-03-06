# frozen_string_literal: true

module Dphil
  #
  # Node in a Phylogenetic tree
  #
  class TreeNode
    include LDOutput
    attr_reader :id, :name, :length, :parent, :children

    def initialize(opts = {})
      self.id = opts[:id]
      self.name = opts[:name]
      self.length = opts[:length]
      self.parent = opts[:parent]
      self.children = opts[:children]
    end

    def id=(id)
      @id = id.to_i
    end

    def name=(name)
      @name = name.to_s
    end

    def length=(length)
      @length = length.to_i
    end

    def parent=(parent)
      unless parent.nil? || parent.is_a?(Integer) || parent.is_a?(TreeNode)
        raise ArgumentError, "Parent must be Integer, Node, or Nil"
      end
      @parent = parent
    end

    def children=(children)
      children = Array(children)
      unless children.all? { |e| e.is_a?(Integer) || e.is_a?(TreeNode) }
        raise ArgumentError, "Parent must be Integer, Node"
      end
      @children = children
    end

    def to_h
      {
        id: id,
        name: name,
        length: length,
        parent: parent,
        children: children,
      }
    end

    def as_json(options = nil)
      to_h.as_json(options)
    end

    def merge!(node)
      node.to_h.each do |k, v|
        method = "#{k}=".to_sym
        send(method, v) if respond_to?(method)
      end
    end
  end
end
