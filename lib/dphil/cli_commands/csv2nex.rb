# frozen_string_literal: true

Dphil::CLI.module_eval do
  desc "Convert a CSV-format collation file into a NEXUS file"
  long_desc <<~DESC
    Convert a CSV-format collation file into a NEXUS file for use with PAUP.
    This expects each column of the CSV to represent data for a single taxon,
    and the first row to contain the names of the taxa.
  DESC

  arg :csv_file

  command :csv2nex do |c|
    c.desc "Transpose rows/columns in CSV"
    c.switch :t, :transpose, negatable: false

    c.desc "Include custom PAUP commands from a file in PAUP block of NEXUS output"
    c.flag :d, :paup_data, arg_name: "file"

    c.desc "Write NEXUS output to file instead of STDOUT"
    c.flag :o, :outfile, arg_name: "file"

    c.action do |_, copts, args|
      nexus_output = Dphil::Csv2NexConverter.new(args[0], copts).convert

      if copts[:outfile].nil?
        puts nexus_output
      else
        abs_outfile = Pathname.new(copts[:outfile]).expand_path
        rel_outfile = abs_outfile.relative_path_from(Pathname.getwd)
        puts "#{File.write(abs_outfile, nexus_output)} bytes written to #{rel_outfile}"
        puts "You can process this file using PAUP with the command\n" \
             "`paup4 [options] #{rel_outfile}`"
      end
    end
  end
end
