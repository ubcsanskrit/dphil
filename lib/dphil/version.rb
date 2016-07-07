# frozen_string_literal: true
require "digest"
require "pathname"

module Dphil
  class << self
    private

    def gem_files
      (Pathname.glob(File.join(GEM_ROOT, "{lib,vendor}", "**", "*.{rb,yml,xml}")) +
        Pathname.glob(File.join(GEM_ROOT, "{Gemfile,dphil.gemspec}"))).sort
    end

    def gem_files_hashes
      gem_files.map do |file|
        "#{file.relative_path_from(GEM_ROOT)}:#{Digest::SHA1.file(file).hexdigest}"
      end
    end

    def gem_files_hash
      Digest::SHA1.base64digest(gem_files_hashes.join("\n"))[/[A-Za-z1-9][A-Za-z0-9]{0,4}/]
    end
  end

  GEM_ROOT = Pathname.new(File.realpath(File.join(__dir__, "..", "..")))
  private_constant :GEM_ROOT

  VERSION = "0.1.0-#{gem_files_hash}"
end
