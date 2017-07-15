# frozen_string_literal: true

require "dphil"
require "gli"

module Dphil
  #
  # GLI-based CLI interface for the library.
  #
  # Not loaded automatically with the rest of the gem.
  #
  module CLI
    extend GLI::App

    program_desc "UBC Sanskrit digital philology CLI tool"
    version Dphil::VERSION
    subcommand_option_handling :normal
    arguments :strict

    desc "Be verbose in output"
    switch :verbose, negatable: false

    # Load individual CLI commands
    commands_from "dphil/cli_commands"
  end
end
