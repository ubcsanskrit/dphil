# frozen_string_literal: true

module Dphil
  class LDDataSet
    include Dphil::LDOutput

    attr_reader :matrix, :trees

    def initialize(matrix:, trees:)
      @matrix = matrix
      @trees = trees
    end

    def to_h
      {
        matrix: matrix,
        trees: trees,
      }
    end

    def as_json(options = nil)
      to_h.as_json(options)
    end
  end
end
