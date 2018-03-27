# frozen_string_literal: true

module Qyu
  module Errors
    # Qyu::Errors::WorkflowDescriptorValidationError
    class WorkflowDescriptorValidationError < Base
      attr_reader :validation_errors
      def initialize(validation_errors)
        super("invalid workflow descriptor: #{validation_errors.join(', ')}")
        @validation_errors = validation_errors
      end
    end
  end
end
