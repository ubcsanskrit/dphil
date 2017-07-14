# frozen_string_literal: true

module Dphil
  #
  # CSV to NEXUS file converter class
  #
  class Csv2NexConverter
    include Dphil::Converter

    def initialize(csv_file, opts = {})
      opts = opts.to_h

      # Load csv file
      @csv = load_csv(csv_file, "r:bom|utf-8")
      @csv = @csv.transpose if opts[:transpose]

      # Load paup file
      if opts[:paup].nil?
        @paup = ""
      else
        @paup = load_file(opts[:paup])
        @paup << "\n" unless @paup.blank? || @paup[-1] == "\n"
        @paup.indent!(2)
        @paup.freeze
      end
    end

    # Perform the conversion and return a string result
    def convert
      # Setup taxa information and orientation
      taxa_count = @csv.first.count
      character_count = @csv.count - 1
      taxa_labels = @csv.first.map { |name| name.to_s.strip.scrub.gsub(/[^A-Za-z0-9]/, "_") }

      # Generate labels and matrix
      character_labels = []
      character_matrix = taxa_labels.map { |t| [t] }
      (1..character_count).each do |r|
        row = @csv[r]
        token_hash = tokenize(row)
        character_label = (token_hash.map do |k, _|
          "'#{sanitize_char(k)}'"
        end).join(" ")
        character_labels << %(#{r} /#{character_label})
        row.each_with_index do |charstate, i|
          token = token_hash[sanitize_char(charstate)]
          character_matrix[i] << (token.nil? ? "-" : token[0])
        end
      end
      character_matrix.map! do |arr|
        "#{arr.shift} #{arr.join('')}"
      end

      # Return NEXUS output
      <<~NEXUS_EOF
        #NEXUS

        BEGIN TAXA;
          TITLE Manuscripts;
          DIMENSIONS NTAX=#{taxa_count};
          TAXLABELS #{taxa_labels.join(' ')};
        END;

        BEGIN CHARACTERS;
          TITLE  Variant_Matrix;
          DIMENSIONS  NCHAR=#{character_count};
          FORMAT DATATYPE = STANDARD RESPECTCASE GAP = - MISSING = ? SYMBOLS = "#{ALPHABET.join(' ')}";
          CHARSTATELABELS #{character_labels.join(', ')};
          MATRIX
            #{character_matrix.join("\n    ")}
        ;

        END;

        BEGIN ASSUMPTIONS;
          OPTIONS DEFTYPE = UNORD;
        END;

        BEGIN PAUP;
        #{@paup}END;
      NEXUS_EOF
    end
  end
end
