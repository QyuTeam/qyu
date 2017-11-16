# frozen_string_literal: true

module Qyu
  module Errors
    # Qyu::Errors::TaskStatusUpdateFailed
    class TaskStatusUpdateFailed < Base
      attr_reader :task_id, :status
      def initialize(task_id, status)
        super("Task status cannot be updated task_id=#{task_id} status=#{status}.")
        @task_id = task_id
        @status = status
      end
    end
  end
end
