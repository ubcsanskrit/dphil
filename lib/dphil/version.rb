# frozen_string_literal: true

require "pathname"

module Dphil
  GEM_ROOT = Pathname.new(File.join(__dir__, "..", "..")).realpath.freeze
  VERSION_BASE = "0.1.0"

  gem_files = (
    Pathname.glob(File.join(GEM_ROOT, "{Gemfile,*.gemspec,Rakefile}")) +
    Pathname.glob(File.join(GEM_ROOT, "{exe,lib,spec,vendor}", "**", "*"))
  ).select { |file| File.file?(file) }

  gem_files_hashes = gem_files.map do |file|
    "#{file.relative_path_from(GEM_ROOT)}:#{Digest::SHA1.file(file).base64digest}"
  end

  gem_files_hash = Digest::SHA1.base64digest(gem_files_hashes.unshift(VERSION_BASE).join("\n"))
                               .gsub(%r{^0+|[\+\=/]+}, "")[0, 5]

  VERSION = "#{VERSION_BASE}.#{gem_files_hash}"
end
