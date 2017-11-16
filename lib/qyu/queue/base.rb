# frozen_string_literal: true

module Qyu
  module Queue
    # Qyu::Queue::Base
    class Base
      # This class acts as an interface for any queue adapter implemented for Qyu
      # Implement the following methods in any queue and it should work seemlessly
      def self.valid_config?(_config)
        fail Qyu::Errors::NotImplementedError
      end

      # Instance methods
      def enqueue_tasks(queue_name, task_ids)
        task_ids.each do |task_id|
          enqueue_task(queue_name, task_id)
        end
      end

      # Instance methods to override
      def enqueue_task(_queue_name, _task_id)
        fail Qyu::Errors::NotImplementedError
      end

      def enqueue_task_to_failed_queue(_queue_name, _task_id)
        fail Qyu::Errors::NotImplementedError
      end

      def fetch_next_message(_queue_name)
        fail Qyu::Errors::NotImplementedError
      end

      def acknowledge_message(_queue_name, _message_id)
        fail Qyu::Errors::NotImplementedError
      end
    end
  end
end
