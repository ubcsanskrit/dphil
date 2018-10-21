# frozen_string_literal: true

module Dphil
  module Refinements
    module EnhancedArray
      refine Array do
        def to_sql_wildcard
          map do |item|
            "%#{item}%"
          end
        end

        def to_regexp_wildcard
          map do |item|
            /#{item}/
          end
        end

        def to_iregexp_wildcard
          map do |item|
            /#{item}/i
          end
        end

        def sort_by_array!(sort_list)
          sort_by! do |item|
            key = block_given? ? yield(item) : item

            Array(sort_list).each.with_index do |sort_item, i|
              if sort_item.is_a?(::Regexp)
                break i if sort_item =~ key
              elsif sort_item == key
                break i
              end
            end
          end
        end

        def sort_by_array(sort_list, &block)
          dup.sort_by_array!(sort_list, &block)
        end

        def stable_sort_by(&block)
          dup.stable_sort_by(&block)
        end

        def stable_sort_by!(&_block)
          n = 0
          sort_by! do |x|
            n += 1
            [yield(x), n]
          end
        end
      end
    end
  end
end
