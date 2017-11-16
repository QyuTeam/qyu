# frozen_string_literal: true

module Qyu
  module Errors
    # Qyu::Errors::WorkflowDescriptorValidatorationError
    class WorkflowDescriptorValidatorationError < Base
      attr_reader :validation_errors
      def initialize(validation_errors)
        super('Invalid Job descriptor.')
        @validation_errors = validation_errors
      end
    end
  end
end
