# frozen_string_literal: true

require "pathname"
require "zlib"

module Dphil
  GEM_ROOT = Pathname.new(File.expand_path("../..", __dir__)).realpath

  VERSION = "0.3.0"

  # VERSION_CHECKSUM = begin
  #   gem_files = (
  #     Pathname.glob(File.join(GEM_ROOT, "{Gemfile,*.gemspec,Rakefile}")) +
  #     Pathname.glob(File.join(GEM_ROOT, "{bin,exe,lib}/**/*")) +
  #     Pathname.glob(File.join(GEM_ROOT, "vendor/*"))
  #   ).select { |file| File.file?(file) }

  #   checksum = gem_files.reduce(Zlib.crc32) do |memo, file|
  #     file_data = file.read.prepend("\n-#{file.relative_path_from(GEM_ROOT)}-\n")
  #     Zlib.crc32(file_data, memo)
  #   end

  #   byte_str = 4.times.each_with_object(String.new(capacity: 4)) do |byte, str|
  #     str << ((checksum >> ((3 - byte) * 8)) & 0xFF).chr
  #   end
  #   [byte_str].pack("m0").gsub(/[\=\+]+/, "").freeze
  # end

  # VERSION_FULL = "#{VERSION}-#{VERSION_CHECKSUM}"
end
