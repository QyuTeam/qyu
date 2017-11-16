# frozen_string_literal: true

module Qyu
  module Errors
    # Qyu::Errors::MessageNotReceived
    class MessageNotReceived < Base
      def initialize
        super('No message retrieved for task from queue.')
      end
    end
  end
end
