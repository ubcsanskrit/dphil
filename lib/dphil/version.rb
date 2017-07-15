# frozen_string_literal: true

require "pathname"
require "zlib"

module Dphil
  GEM_ROOT = Pathname.new(File.join(__dir__, "..", "..")).realpath.freeze

  VERSION = "0.1.2"

  VERSION_CHECKSUM = begin
    gem_files = (
      Pathname.glob(File.join(GEM_ROOT, "{Gemfile,*.gemspec,Rakefile}")) +
      Pathname.glob(File.join(GEM_ROOT, "{exe,lib,vendor}", "**", "*"))
    ).select { |file| File.file?(file) }

    checksum = gem_files.reduce(Zlib.crc32) do |memo, file|
      file_data = File.read(file)
                      .prepend("#{file.relative_path_from(GEM_ROOT)}\n---\n")
      Zlib.crc32(file_data, memo)
    end

    byte_str = 3.downto(0).each_with_object(String.new(capacity: 4)) do |byte, str|
      str << ((checksum >> (byte * 8)) & 0xFF).chr
    end
    [byte_str].pack("m0").gsub(/[\=\+]+/, "").freeze
  end

  VERSION_FULL = "#{VERSION}-#{VERSION_CHECKSUM}"
end
