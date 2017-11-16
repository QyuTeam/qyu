# frozen_string_literal: true

module Qyu
  module Errors
    # Qyu::Errors::LockNotAcquired
    class LockNotAcquired < Base
      def initialize
        super('Lock was not acquired.')
      end
    end
  end
end
