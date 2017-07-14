# frozen_string_literal: true

Dphil::CLI.module_eval do
  desc "Convert a CSV-format collation file into a NEXUS file"
  long_desc <<~EOS
    Convert a CSV-format collation file into a NEXUS file for use with PAUP.
    This expects each column of the CSV to represent data for a single taxon,
    and the first row to contain the names of the taxa.
  EOS

  arg :csv_file

  command :csv2nex do |c|
    c.desc "Transpose rows/columns in CSV"
    c.switch :t, :transpose, negatable: false

    c.desc "Include PAUP commands from a file in NEX output as a PAUP block"
    c.flag :p, :paup, arg_name: "file"

    c.desc "Write output to file instead of STDOUT"
    c.flag :o, :outfile, arg_name: "file"

    c.action do |_, copts, args|
      nexus_output = Dphil::Csv2NexConverter.new(args[0], copts).convert

      if copts[:outfile].nil?
        puts nexus_output
      else
        bytes = File.write(copts[:outfile], nexus_output)
        puts "#{bytes} bytes written to #{copts[:outfile]}"
      end
    end
  end
end
