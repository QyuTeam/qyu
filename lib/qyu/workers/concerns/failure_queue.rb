# frozen_string_literal: true

module Qyu
  module Workers
    module Concerns
      # Qyu::Workers::Concerns::FailureQueue
      #
      # Adds ability to workers enqueue failed task to another queue
      #
      # Qyu::Worker.new do
      #   failure_queue true
      #   # or
      #   failure_queue false
      # end
      #
      module FailureQueue

        # Configures failure queue
        #
        #   failure_queue false # default
        #   failure_queue true
        #
        # @param [Boolean]
        def failure_queue(fq)
          @failure_queue = fq
        end
      end
    end
  end
end
