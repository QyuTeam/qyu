# frozen_string_literal: true

module Qyu
  module Errors
    # Qyu::Errors::TaskNotFound
    class TaskNotFound < Base
      attr_reader :task_id, :original_error
      def initialize(task_id, original_error)
        super("Task not found with id=#{task_id}.")
        @original_error = original_error
        @task_id = task_id
      end
    end
  end
end
