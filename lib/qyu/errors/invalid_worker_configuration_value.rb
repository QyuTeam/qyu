# frozen_string_literal: true

module Qyu
  module Errors
    # Qyu::Errors::InvalidWorkerConfigurationValue
    class InvalidWorkerConfigurationValue < Base
      def initialize(configuration_name, configuration_value = nil)
        super("invalid worker configuration value #{configuration_name}: #{configuration_value}")
      end
    end
  end
end
