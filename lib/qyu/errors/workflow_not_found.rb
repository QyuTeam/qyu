# frozen_string_literal: true

module Qyu
  module Errors
    # Qyu::Errors::WorkflowNotFound
    class WorkflowNotFound < Base
      attr_reader :key, :workflow_id
      def initialize(key, workflow_id)
        super("Workflow not found with #{key}=#{workflow_id}.")
        @key = key
        @workflow_id = workflow_id
      end
    end
  end
end
