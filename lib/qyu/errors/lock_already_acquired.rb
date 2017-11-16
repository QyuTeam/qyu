# frozen_string_literal: true

module Qyu
  module Errors
    # Qyu::Errors::LockAlreadyAcquired
    class LockAlreadyAcquired < Base
      def initialize
        super('Lock already acquired.')
      end
    end
  end
end
