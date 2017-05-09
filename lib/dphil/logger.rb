# frozen_string_literal: true

require "active_support/logger"

require "dphil/log_formatter"

# Namespace module definition
module Dphil
  module_function

  def logger
    @logger ||= begin
      if defined?(::Rails) && defined?(::Rails.logger)
        ::Rails.logger
      else
        file_logger = ActiveSupport::Logger.new(File.join(GEM_ROOT, "dphil.log"))
        file_logger.formatter = LogFormatter.new
        if Constants::DEBUG
          logger = ActiveSupport::Logger.new(STDERR)
          logger.formatter = file_logger.formatter
          file_logger.extend(ActiveSupport::Logger.broadcast(logger))
        end
        file_logger
      end
    end
  end
end
