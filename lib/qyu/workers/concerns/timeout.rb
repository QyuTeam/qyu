# frozen_string_literal: true

require 'timeout'

module Qyu
  module Workers
    module Concerns
      # Qyu::Workers::Concerns::Timeout
      #
      # Adds timeout to running tasks in a worker
      #
      # Qyu::Worker.new do
      #   timeout 0 # disabled (default)
      #   # or
      #   timeout 3600
      # end
      #
      module Timeout

        # Configures timeout
        #
        #   timeout 0 # default
        #   timeout 3600
        #
        # @param [Integer]
        def timeout(seconds)
          @timeout = seconds.to_i
        end
      end
    end
  end
end
