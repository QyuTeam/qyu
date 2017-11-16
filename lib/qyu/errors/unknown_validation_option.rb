# frozen_string_literal: true

module Qyu
  module Errors
    # Qyu::Errors::UnknownValidationOption
    class UnknownValidationOption < Base
      def initialize(option)
        super("Validation option #{option} is unknown")
      end
    end
  end
end
