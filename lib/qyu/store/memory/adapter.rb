# frozen_string_literal: true

module Qyu
  module Store
    module Memory
      class Adapter < Qyu::Store::Base
        TYPE = :memory

        def initialize(_config)
          @workflows = {}
          @jobs = {}
          @tasks = {}
          @locks = {}
          @semaphore = Mutex.new
        end

        def self.valid_config?(_config)
          # TODO
          true
        end

        def find_or_persist_task(name, queue_name, payload, job_id, parent_task_id)
          matching_task = @tasks.detect do |_id, attrs|
            attrs['job_id'] == job_id \
            && attrs['name'] == name \
            && attrs['payload'] == payload \
            && attrs['queue_name'] == queue_name \
            && attrs['parent_task_id'] == parent_task_id
          end
          return matching_task[0] if matching_task

          id = Qyu::Utils.uuid
          @tasks[id] = {
            'name' => name,
            'queue_name' => queue_name,
            'parent_task_id' => parent_task_id,
            'status' => Qyu::Task::Status::QUEUED,
            'payload' => payload,
            'job_id' => job_id
          }
          yield(id)
          id
        end

        def persist_workflow(name, descriptor)
          id = Qyu::Utils.uuid
          @workflows[id] = {
            'name'       => name,
            'descriptor' => descriptor
          }
          id
        end

        def persist_job(workflow, payload)
          id = Qyu::Utils.uuid
          @jobs[id] = {
            'payload'  => payload,
            'workflow' => workflow
          }
          id
        end

        def find_task(id)
          @tasks[id]
        end

        def find_task_ids_by_job_id_and_name(job_id, name)
          @tasks.select { |_id, attrs| attrs['job_id'] == job_id && attrs['name'] == name }.map { |(id, _attr)| id }
        end

        def find_task_ids_by_job_id_name_and_parent_task_ids(job_id, name, parent_task_ids)
          @tasks.select { |_id, attrs| attrs['job_id'] == job_id && attrs['name'] == name && parent_task_ids.include?(attrs['parent_task_id']) }.map { |(id, _attr)| id }
        end

        def select_tasks_by_job_id(job_id)
          @tasks.select { |_id, attrs| attrs['job_id'] == job_id }.map { |id, attrs| attrs.merge('id' => id) }
        end

        def find_workflow(id)
          @worflows[id]
        end

        def find_workflow_by_name(name)
          @worflows.detect do |_id, wflow|
            wflow['name'] == name
          end.last
        end

        def find_job(id)
          @jobs[id]
        end

        def select_jobs(limit, offset, order = :asc)
          ids = @jobs.keys[offset, limit]
          selected = ids.map { |id| { id: id }.merge(@jobs[id]) }
          return selected if order == :asc
          selected.reverse
        end

        def count_jobs
          @jobs.count
        end

        def lock_task!(id, lease_time)
          uuid = Qyu::Utils.uuid
          locked = false
          locked_until = nil
          @semaphore.synchronize do
            if @locks[id].nil? || @locks[id][:locked_until] < Time.now
              locked_until = Qyu::Utils.seconds_after_time(lease_time)
              @locks[id] = { locked_by: uuid, locked_until: locked_until }
              locked = true
            end
          end

          return [nil, nil] unless locked

          [uuid, locked_until]
        end

        def unlock_task!(id, lease_token)
          unlocked = false
          @semaphore.synchronize do
            if @locks[id][:locked_by] == lease_token
              @locks.delete(id)
              unlocked = true
            end
          end

          unlocked
        end

        def update_status(id, status)
          @tasks[id]['status'] = status
        end

        def renew_lock_lease(id, lease_time, lease_token)
          locked_until = nil
          @semaphore.synchronize do
            if @locks[id][:locked_by] == lease_token && Time.now <= @locks[id][:locked_until]
              locked_until = Qyu::Utils.seconds_after_time(lease_time)
              @locks[id] = { locked_by: lease_token, locked_until: locked_until }
            end
          end

          locked_until
        end

        def transaction
          # TODO
          yield
        end
      end
    end
  end
end