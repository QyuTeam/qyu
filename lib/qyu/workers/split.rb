# frozen_string_literal: true

module Qyu
  module Workers
    # Qyu::Workers::Split
    class Split < Base

      attr_accessor :splittable

      def work(queue_name, starts:, variable:, size: 25)
        super do |task|
          if block_given?
            # splittable variable can be assigned via `splittable = [1, 2, 3...]` via a block
            yield(task)
          else
            @splittable = task.payload[variable]
          end

          @splittable.each_slice.with_index(size) do |slice, i|
            log(:debug, "Split started for queue '#{queue_name}'")
            new_payload = task.payload.merge({ variable => slice })
            task.job.create_task(task, starts, new_payload)
          end
        end
      end
    end
  end
end
