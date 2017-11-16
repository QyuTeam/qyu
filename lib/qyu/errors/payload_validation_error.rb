# frozen_string_literal: true

module Qyu
  module Errors
    # Qyu::Errors::PayloadValidationError
    class PayloadValidationError < Base
      def initialize(validation_errors_hash)
        super("Validation failed for payload fields: #{validation_errors_hash}.")
      end
    end
  end
end
