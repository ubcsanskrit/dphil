# frozen_string_literal: true

module Dphil
  #
  # CSV to NEXUS file converter class
  #
  class Csv2NexConverter
    include Dphil::Converter

    def initialize(csv_file, opts = {})
      @opts = opts.to_h

      # Load csv file
      @csv = load_csv(csv_file, "r:bom|utf-8")
      @csv = @csv.transpose if @opts[:transpose]

      # Load paup file
      if @opts[:paup_data].nil?
        @opts[:paup_data] = File.join(GEM_ROOT, "vendor", "default_commands.paup")
      end
      @paup = load_file(@opts[:paup_data])
      @paup << "\n" unless @paup.blank? || @paup[-1] == "\n"
      @paup.indent!(2)
      @paup.freeze
    end

    # Perform the conversion and return a string result
    def convert
      # Setup taxa information and orientation
      taxa_count = @csv.first.count
      character_count = @csv.count - 1
      taxa_labels = @csv.first.map { |name| name.to_s.strip.scrub.gsub(/[^A-Za-z0-9]/, "_") }

      # Normalize character states for each taxon
      normalize_states!

      # Generate labels and matrix
      character_labels = []
      character_matrix = taxa_labels.map { |t| [t] }
      (1..character_count).each do |r|
        row = @csv[r]
        token_hash = tokenize(row)
        character_label = (token_hash.map do |k, _|
          "'#{sanitize_char(k)}'"
        end).join(" ")
        if @opts[:type2]
          next unless token_hash.length == 2 && token_hash.all? { |_, v| v[1] >= 2 }
          # STDERR.puts("Char #{r} is Type 2: #{token_hash.inspect}")
        end
        character_labels << %(#{r} /#{sanitize_char(character_label)})
        row.each_with_index do |charstate, i|
          token = token_hash[sanitize_char(charstate)]
          character_matrix[i] << (token.nil? ? "-" : token[0])
        end
      end
      # Fix character count after filtering
      character_count = [0, character_matrix[0].length - 1].max
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

    private

    def normalize_states!
      taxa_count = @csv.first.count
      character_count = @csv.count - 1
      (0..taxa_count).each do |taxa_i|
        lemma_window = []
        (1..character_count).each do |char_i|
          lemma_window << char_i if @csv[char_i][taxa_i].present?
          next unless lemma_window.length == 2 || char_i == character_count
          lemmata = lemma_window.map { |l| @csv[l][taxa_i] }
          norm_result = Dphil::Normalize.normalize_iast(*lemmata)
          if lemmata != norm_result
            # STDERR.puts("#{@csv[0][taxa_i]} #{lemma_window}:")
            # STDERR.puts("  #{lemmata} #{norm_result}")
          end
          norm_result.each_with_index do |l, i|
            @csv[lemma_window[i]][taxa_i] = l
          end
          lemma_window.shift
        end
      end
    end
  end
end
