# frozen_string_literal: true

module Qyu
  module Workers
    # Qyu::Workers::Split
    #
    # Starts a worker to split a certain payload key into multiple jobs
    #
    # Qyu::SplitWorker.new do
    #   slice_size 25
    #   payload_key 'array'
    # end
    #
    class Split < Base
      include Qyu::Workers::Concerns::Split

      attr_accessor :splittable

      # Assign a splittable variable
      # by being at the end of a block
      # worker.work('queue') do
      #   # do anything
      #   # splittable variable must be at the end
      #   [1, 2, 3, 4, 5, 6, 6]
      # end
      #
      # or by passing
      # payload_key 'array'
      # to worker initializer then just
      # worker.work('queue')
      # @param queue_name [String]
      def work(queue_name, blocking: true)
        validate_split_parameters!

        super do |task|
          if block_given?
            @splittable = yield(task)
          else
            # or by passing
            # payload_key 'array'
            # to worker initializer
            @splittable = task.payload[@payload_key]
          end

          @splittable.each_slice(@slice_size).with_index do |slice, i|
            log(:debug, "Split started for queue '#{queue_name}'")
            input = @sample ? slice.sample : slice
            new_payload = task.payload.merge({ @payload_key => input })
            task_names_to_start = task.descriptor['starts_parallel'] || task.descriptor['starts_manually']
            task_names_to_start.each do |task_name_to_start|
              task.job.create_task(task, task_name_to_start, new_payload)
            end
          end
        end
      end
    end
  end
end
