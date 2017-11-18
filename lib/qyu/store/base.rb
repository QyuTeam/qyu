# frozen_string_literal: true

module Qyu
  module Store
    # Qyu::Store::Base
    class Base
      # This class acts as an interface for any store implemented for Qyu
      # Implement the following methods in any store and it should work seemlessly
      def self.valid_config?(_config)
        fail Qyu::Errors::NotImplementedError
      end

      def transaction
        fail Qyu::Errors::NotImplementedError
      end

      ## Workflow
      def persist_workflow(name, descriptor)
        fail Qyu::Errors::NotImplementedError
      end

      def find_workflow(_id)
        fail Qyu::Errors::NotImplementedError
      end

      def find_workflow_by_name(_name)
        fail Qyu::Errors::NotImplementedError
      end

      def delete_workflow(_id)
        fail Qyu::Errors::NotImplementedError
      end

      def delete_workflow_by_name(name)
        fail Qyu::Errors::NotImplementedError
      end

      ## Job
      def persist_job(_workflow, _payload)
        fail Qyu::Errors::NotImplementedError
      end

      def find_job(_id)
        fail Qyu::Errors::NotImplementedError
      end

      def select_jobs(_limit, _offset, _order = :asc)
        fail Qyu::Errors::NotImplementedError
      end

      def count_jobs
        fail Qyu::Errors::NotImplementedError
      end

      def delete_job(_id)
        fail Qyu::Errors::NotImplementedError
      end

      def clear_completed_jobs
        fail Qyu::Errors::NotImplementedError
      end

      ## Task

      def find_or_persist_task(_name, _payload, _job_id, _parent_task_id)
        fail Qyu::Errors::NotImplementedError
      end

      def find_task(_id)
        fail Qyu::Errors::NotImplementedError
      end

      def find_task_ids_by_job_id_and_name(_job_id, _name)
        fail Qyu::Errors::NotImplementedError
      end

      def find_task_ids_by_job_id_name_and_parent_task_ids(_job_id, _name, _parent_task_ids)
        fail Qyu::Errors::NotImplementedError
      end

      def lock_task!(_id, _lease_time)
        fail Qyu::Errors::NotImplementedError
      end

      def unlock_task!(_id, _lease_token)
        fail Qyu::Errors::NotImplementedError
      end

      def renew_lock_lease(_id, _lease_time, _lease_token)
        fail Qyu::Errors::NotImplementedError
      end

      def update_status(_id, _status)
        fail Qyu::Errors::NotImplementedError
      end

      def select_tasks_by_job_id
        fail Qyu::Errors::NotImplementedError
      end
    end
  end
end
