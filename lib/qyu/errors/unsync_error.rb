# frozen_string_literal: true

module Qyu
  module Errors
    # Qyu::Errors::InvalidQueueName
    class UnsyncError < Base
      def initialize
        super('Not all tasks have been started yet')
      end
    end
  end
end
