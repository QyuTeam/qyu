# frozen_string_literal: true

module Qyu
  module Errors
    # Qyu::Errors::InvalidQueueName
    class InvalidQueueName < Base
      def initialize
        super('Queue name is invalid.')
      end
    end
  end
end
