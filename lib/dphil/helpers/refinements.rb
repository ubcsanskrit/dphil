# frozen_string_literal: true
module Dphil
  module Helpers
    module Refinements
      refine Object do
        def try_first
          respond_to?(:first) ? first : self
        end
      end
    end
  end
end
