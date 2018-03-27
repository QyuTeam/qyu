# frozen_string_literal: true

module Qyu
  module Errors
    # Qyu::Errors::MissingSplitParameters
    class MissingSplitParameters < Base
      def initialize(parameter_name)
        super("Missing split parameter: #{parameter_name}")
      end
    end
  end
end
