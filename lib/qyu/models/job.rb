# frozen_string_literal: true

module Qyu
  class Job
    attr_reader :descriptor, :payload, :id, :created_at, :updated_at

    def self.create(workflow:, payload:)
      workflow = Workflow.find_by(name: workflow) if workflow.is_a?(String)
      id = persist(workflow, payload)
      time = Time.now
      new(id, workflow, payload, time, time)
    end

    def self.find(id)
      job_attrs = Qyu.store.find_job(id)
      new(id, job_attrs['workflow'], job_attrs['payload'],
          job_attrs['created_at'], job_attrs['updated_at'])
    end

    def self.select(limit: 30, offset: 0, order: :asc)
      job_records = Qyu.store.select_jobs(limit, offset, order)
      job_records.map do |record|
        new(record['id'], record['workflow'], record['payload'],
            record['created_at'], record['updated_at'])
      end
    end

    def self.count
      Qyu.store.count_jobs
    end

    def self.delete(id)
      Qyu.store.delete_job(id)
    end

    def self.clear_completed
      Qyu.store.clear_completed_jobs
    end

    def start
      descriptor['starts'].each do |task_name|
        create_task(nil, task_name, payload)
      end
    end

    def queue_name(task_name)
      descriptor['tasks'][task_name]['queue']
    end

    def next_task_names(src_task_name)
      {
        'without_params' => descriptor['tasks'][src_task_name]['starts'],
        'with_params' => descriptor['tasks'][src_task_name]['starts_with_params']
      }
    end

    def tasks_to_wait_for(task)
      descriptor['tasks'][task.name]['waits_for'].keys
    end

    def sync_condition(task, task_name)
      descriptor['tasks'][task.name]['waits_for'][task_name]['condition']
    end

    def create_task(parent_task, task_name, payload)
      parent_task_id = parent_task.nil? ? nil : parent_task.id
      Qyu.logger.debug "Task (ID=#{parent_task_id}) created a new task"
      Qyu::Task.create(
        queue_name: queue_name(task_name),
        attributes: {
                      'name' => task_name,
                      'parent_task_id' => parent_task_id,
                      'job_id' => id,
                      'payload' => task_payload(payload, task_name)
                    })
    end

    def create_next_tasks(parent_task, payload)
      Qyu.logger.debug "Creating next tasks for task (ID=#{parent_task.id})"
      next_tasks = next_task_names(parent_task.name)
      Qyu.logger.debug "Next task names: #{next_tasks}"

      next_tasks['without_params']&.each do |next_task_name|
        create_task(parent_task, next_task_name, payload)
      end

      next_tasks['with_params']&.each do |next_task_name, params|
        updated_payload = payload.dup
        params.each do |param_name, value_eqs|
          f = value_eqs.keys[0]
          x = value_eqs.values[0]
          updated_payload[param_name] = calc_func_x(parent_task, f, x)
        end
        create_task(parent_task, next_task_name, updated_payload)
      end
    end

    def find_task_ids_by_name(task_name)
      Qyu.store.find_task_ids_by_job_id_and_name(id, task_name)
    end

    def find_task_ids_by_name_and_ancestor_task_id(task_name, ancestor_task_id)
      ancestor_task_name = Qyu.store.find_task(ancestor_task_id)['name']
      tasks_path = [task_name]
      key_idx = 0

      while tasks_path[-1] != ancestor_task_name
        found_task = descriptor['tasks'].detect do |_, desc|
          all_task_names = []
          all_task_names.concat(desc['starts'] || [])
          all_task_names.concat((desc['starts_with_params'] || {}).keys)
          all_task_names.concat(desc['starts_manually'] || [])
          all_task_names.include?(tasks_path[-1])
        end
        tasks_path << found_task[key_idx] if found_task
      end

      tasks_topdown_path = tasks_path.reverse
      # remove topmost task (ancestor_task) from the path
      tasks_topdown_path.shift

      # traverse task tree from top down, and find the <task_name> "descendants" of <ancestor_task>
      parent_task_ids = [ancestor_task_id]
      tasks_topdown_path.each do |t_name|
        parent_task_ids = Qyu.store.find_task_ids_by_job_id_name_and_parent_task_ids(id, t_name, parent_task_ids)
      end
      parent_task_ids
    end

    def task_status_counts
      Qyu.store.task_status_counts(id)
    end

    def [](attribute)
      public_send(attribute)
    end

    private_class_method :new

    private

    def initialize(id, workflow, payload, created_at = nil, updated_at = nil)
      @workflow = workflow
      @descriptor = @workflow['descriptor']
      @payload = payload
      @id = id
      @created_at = created_at
      @updated_at = updated_at
    end

    def self.persist(workflow, payload)
      workflow = Qyu::Workflow.find_by(name: workflow) if workflow.is_a?(String)
      Qyu.store.persist_job(workflow, payload)
    end

    def calc_func_x(task, func, x)
      if func == 'count'
        find_task_ids_by_name_and_ancestor_task_id(x, task.id).count
      else
        fail Qyu::Errors::NotImplementedError
      end
    end

    def task_payload(payload, task_name)
      shared_payload = payload.dup.reject { |k, _v| task_name?(k) }
      shared_payload.merge!(payload[task_name]) if payload[task_name].is_a?(Hash)
      shared_payload
    end

    def task_name?(string)
      descriptor['tasks'].keys.include?(string)
    end
  end
end
