# frozen_string_literal: true

module Qyu
  module Errors
    # Qyu::Errors::InvalidQueueName
    class InvalidQueueName < Base
      def initialize
        super('Invalid queue name.')
      end
    end
  end
end
