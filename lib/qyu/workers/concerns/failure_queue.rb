# frozen_string_literal: true

module Qyu
  module Workers
    module Concerns
      # Qyu::Concerns::FailureQueue
      module FailureQueue
        # Adds ability to workers enqueue failed task to another queue
        #
        # Qyu::Worker.new do
        #   failure_queue true
        #   # or
        #   failure_queue false
        # end
        #

        def failure_queue(fq)
          @failure_queue = fq
        end
      end
    end
  end
end
