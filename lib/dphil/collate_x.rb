# frozen_string_literal: true

module Dphil
  module CollateX
    using ::Dphil::Refinements::EnhancedArray

    def self.post_process(input, threshold = 0.8)
      witnesses = input["witnesses"]
      witness_size = witnesses.each_with_object({}).with_index { |(_, h), i| h[i] = 0 }
      out_table = []

      # Iterate over table of collated "rows".
      input["table"].each.with_index do |row, _index|
        # We'll store the new split row as a hash so that keys can be used as comparison points.
        split_rows = {}

        # Iterate over witnesses in the row
        row.each.with_index do |witness, id|
          next if witness.empty?
          witness_size[id] += witness.size
          token_str = witness.map { |t| t["n"] }.join(" ")

          # Create a list of comparisons between current token and previous tokens in this row
          matches = split_rows.keys.map { |key| [key, Dphil::Compare.compare_words(token_str, key)] }
          matches.sort! { |a, b| a[1] <=> b[1] }
          # Add token to a new row or an existing one if a match occurred.
          if matches.empty? || matches.last[1] < threshold
            split_rows[token_str] = Array.new(row.size) { |_| [] }
            split_rows[token_str][id].concat(witness)
          else
            split_rows[matches.last[0]][id].concat(witness)
          end
        end

        # Sorts rows and appends to the output table.
        new_rows = split_rows.values

        new_rows.stable_sort_by! do |new_row|
          new_row.count(&:empty?)
        end

        new_rows.stable_sort_by! do |new_row|
          (new_row.find_index(&:empty?) || new_rows.size) * -1
        end

        out_table.concat(new_rows)
      end

      # # Re-sort columns and witnesses by size, descending from longest witness
      # witness_map = witness_size.sort_by { |_, v| v }.reverse!.map! { |v| v[0] }
      # new_witnesses = witness_map.map { |v| witnesses[v] }
      # new_table = out_table.map do |old_row|
      #   new_row = Array.new(new_witnesses.size)
      #   witness_map.each.with_index { |old_id, new_id| new_row[new_id] = old_row[old_id] }
      #   new_row
      # end

      {
        "witnesses" => witnesses,
        "table" => out_table,
      }
    end
  end
end
