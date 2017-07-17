# frozen_string_literal: true

Dphil::CLI.module_eval do
  desc "Convert a CSV-format collation file into a JSON-LD dataset"
  long_desc <<~EOS
    Convert a CSV-format collation file into a JSON-LD dataset, generating trees
    using PAUP as part of the process.
    This expects each column of the CSV to represent data for a single taxon,
    and the first row to contain the names of the taxa.
  EOS

  arg :csv_file

  command :csv2ld do |c|
    c.desc "Transpose rows/columns in CSV"
    c.switch :t, :transpose, negatable: false

    c.desc "Specify the location of the PAUP executable"
    c.flag :p, :paup_cmd, arg_name: "file", default_value: "paup4"

    c.desc "Include custom PAUP commands from a file in PAUP block of NEXUS output"
    c.flag :d, :paup_data, arg_name: "file"

    c.desc "Write JSON-LD output to file instead of STDOUT"
    c.flag :o, :outfile, arg_name: "file"

    c.action do |_, copts, args|
      # Check that PAUP command exists
      paup_cmd = `command -v #{Shellwords.shellescape(copts[:paup_cmd])}`.strip
      raise "PAUP command `#{copts[:paup_cmd]}` could not be found." if paup_cmd.empty?

      # Set absolute path of CSV input
      csv_file = Pathname.new(args[0]).realpath

      Dir.mktmpdir("dphil-csv2ld") do |dir|
        Dir.chdir(dir) do
          # Run Csv2Nex conversion
          File.write("csv2ld.nex", Dphil::Csv2NexConverter.new(csv_file, copts).convert)

          # Run PAUP
          `#{paup_cmd} -n csv2ld.nex`

          # Compile JSON-LD Dataset
          matrix = Dphil::CharacterMatrix.from_csv(csv_file, transpose: copts[:transpose])
          paup_trees = Dphil::PAUP.parse_trees("paup.log")
          trees = paup_trees.each_with_object({}) do |(k, v), acc|
            next unless k.is_a?(Integer)
            acc[k] = Dphil::Tree.new(k, v[:lengths], v[:stats])
          end

          cons_tree = Dphil::NewickTree.tree_from_nex(
            "con.tree",
            taxa_map: matrix.taxa_names.transform_values { |v| v.gsub(/[\-\_]/, " ") }
          )
          trees[0] = cons_tree

          dataset = Dphil::LDDataSet.new(matrix: matrix, trees: trees)
          @dataset_ld = JSON.pretty_generate(dataset.as_jsonld)
        end
      end

      if copts[:outfile].nil?
        puts @dataset_ld
      else
        abs_outfile = Pathname.new(copts[:outfile]).expand_path
        rel_outfile = abs_outfile.relative_path_from(Pathname.getwd)
        puts "#{File.write(copts[:outfile], @dataset_ld)} bytes written to #{rel_outfile}"
      end
    end
  end
end
