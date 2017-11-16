# frozen_string_literal: true

module Qyu
  module Errors
    # Qyu::Errors::InvalidTaskAttributes
    class InvalidTaskAttributes < Base
      def initialize
        super('Invalid task attributes.')
      end
    end
  end
end
