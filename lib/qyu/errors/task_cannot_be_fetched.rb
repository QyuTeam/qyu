# frozen_string_literal: true

module Qyu
  module Errors
    # Qyu::Errors::TaskCannotBeFetched
    # TODO: rethink this...
    class TaskCannotBeFetched < Base
      attr_reader :original_error, :queue_name, :message_id, :task_id
      def initialize(queue_name, message_id, task_id, original_error)
        super("Task cannot be fetched from queue=#{queue_name} with message_id=#{message_id} task_id=#{task_id}.")
        @original_error = original_error
        @task_id = task_id
        @message_id = message_id
        @queue_name = queue_name
      end
    end
  end
end
