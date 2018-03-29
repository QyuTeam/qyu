# frozen_string_literal: true

module Qyu
  module Workers
    # Qyu::Workers::Sync
    class Sync < Base
      def work(queue_name, blocking: true)
        super do |task|
          job = task.job
          task_names_to_wait_for = job.tasks_to_wait_for(task)
          log(:debug, "Task names to wait for: #{task_names_to_wait_for}")
          task_names_to_wait_for.each do |task_name|
            sync_condition = job.sync_condition(task, task_name)
            log(:debug, "Task: #{task_name}, Sync condition: #{sync_condition}")
            if respond_to?(sync_condition['function'], true)
              __send__(sync_condition['function'], job, task, task_name, sync_condition['param'])
              # execute attached sync block only if codition passes (i.e. No errors raised)
              yield(task) if block_given?
            else
              fail Qyu::Errors::NotImplementedError
            end
          end
        end
      end

      private

      def eq_completed(job, task, task_name_to_wait_for, sync_param_name)
        sync_param_value = task.payload[sync_param_name]
        log(:debug, "Task: #{task_name_to_wait_for}, Sync param value: #{sync_param_value}")
        parent_task_id = task.parent_task_id
        log(:debug, "Task: #{task_name_to_wait_for}, Parent task ID: #{parent_task_id}")
        task_ids = job.find_task_ids_by_name_and_ancestor_task_id(task_name_to_wait_for, parent_task_id)
        log(:debug, "Task: #{task_name_to_wait_for}, Task IDs: #{task_ids}")

        if task_ids.size < sync_param_value
          log(:debug, 'Re-enqueuing sync task')
          fail Qyu::Errors::UnsyncError
        end

        check_completion!(task_ids)
      end

      def completed(job, task, task_name_to_wait_for, _sync_param_name)
        parent_task_id = task.parent_task_id
        log(:debug, "Task: #{task_name_to_wait_for}, Parent task ID: #{parent_task_id}")
        task_ids = job.find_task_ids_by_name_and_ancestor_task_id(task_name_to_wait_for, parent_task_id)
        log(:debug, "Task: #{task_name_to_wait_for}, Task IDs: #{task_ids}")
        if task_ids.empty?
          log(:debug, 'Re-enqueuing sync task')
          fail Qyu::Errors::UnsyncError
        end
        check_completion!(task_ids)
      end

      def check_completion!(task_ids)
        task_ids.each do |task_id|
          state = Qyu::Status.new(task_id)
          log(:debug, "[CHECK_COMPLETION] Task ID: #{task_id}, Status: #{state.status}")
          next if state.completed?
          fail Qyu::Errors::UnsyncError
        end
      end
    end
  end
end
