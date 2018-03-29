# frozen_string_literal: true

module Qyu
  # Qyu::Task
  # A Task represents a unit of work in a workflow.
  # Conceptually a Task:
  # - may not exist outside the context of a queue.
  # - it is created ON the queue
  # - it remains on the queue until it was successfully processed (or failed "enough" times)
  class Task
    attr_reader :queue_name, :payload, :status, :id, :job_id, :name, :parent_task_id,
                :message_id, :created_at, :updated_at

    LEASE_PERCENTAGE_THRESHOLD_BEFORE_RENEWAL = 0.8
    POLL_INTERVAL                             = 0.5

    # @returns Task
    # by defintion Task.create does 2 things:
    # - persists the Task in the Store
    # - enqueues the Task to the Queue
    # We have to make sure that a Task is unique in the Store. Because of this
    # create first looks up if the task has already been persisted. If it exists then
    # there is no need to persist it again, only to enqueue it.
    # Double (or multiple) delivery of messages is allowed and handled at worker level.
    # Possible scenario:
    # A Job failed at some point. A few of its tasks completed successfully, others failed.
    # Because of this, certain tasks haven't even been created.
    # When we restart the job, the tasks will be recreated. If a task has already existed,
    # and completed, then that state will be unchanged, and when the worker picks it up,
    # will notice the completed state, acknowledge the message, and continue the next steps.
    def self.create(queue_name: nil, attributes: nil)
      fail Qyu::Errors::InvalidTaskAttributes unless valid_attributes?(attributes)
      fail Qyu::Errors::InvalidQueueName unless valid_queue_name?(queue_name)
      Qyu.logger.debug "find_or_persist queue_name=#{queue_name} and attributes=#{attributes}"
      task_id = Qyu.store.find_or_persist_task(
        attributes['name'],
        queue_name,
        attributes['payload'],
        attributes['job_id'],
        attributes['parent_task_id']
      ) do |t_id|
        Qyu.logger.debug "enqueue queue_name=#{queue_name} and task_id=#{t_id}"
        Qyu.queue.enqueue_task(queue_name, t_id)
      end

      new(task_id, attributes, queue_name)
    end

    # @returns Task
    def self.fetch(queue_name)
      fail Qyu::Errors::InvalidQueueName unless valid_queue_name?(queue_name)
      begin
        message    = Qyu.queue.fetch_next_message(queue_name)
        task_id    = message['task_id']
        task_attrs = Qyu.store.find_task(task_id)
      rescue => ex
        message ||= {}
        raise Qyu::Errors::CouldNotFetchTask.new(queue_name, message['id'], message['task_id'], ex)
      end
      new(task_id, task_attrs, queue_name, message['id'])
    end

    def self.select(job_id:)
      Qyu.store.select_tasks_by_job_id(job_id).map do |task|
        new(task['id'], task, task['queue_name'])
      end
    end

    def self.valid_attributes?(_attributes)
      true
    end

    def self.valid_queue_name?(queue_name)
      !queue_name.nil? && queue_name != ''
    end

    def acknowledgeable?
      @status.completed? || @status.invalid_payload?
    end

    def completed?
      @status.completed?
    end

    def locked?
      !@lease_token.nil? && !@locked_until.nil? && Time.now < @locked_until
    end

    def lock!
      fail Qyu::Errors::LockAlreadyAcquired if locked?
      Qyu.logger.debug "Task with ID=#{id} lock!"

      @lease_token, @locked_until = Qyu.store.lock_task!(id, Qyu.config.store[:lease_period])
      Qyu.logger.debug "lease_token = #{@lease_token} | locked_until = #{@locked_until}"
      return false if @lease_token.nil?

      schedule_renewal
      true
    end

    def unlock!
      fail Qyu::Errors::LockNotAcquired unless locked?
      Qyu.logger.debug "Task with ID=#{id} unlocking!"

      @lease_thread&.kill
      success = Qyu.store.unlock_task!(id, @lease_token)
      if success
        @lease_token  = nil
        @locked_until = nil
      end

      success
    end

    def mark_queued
      Qyu.store.update_status(id, Status::QUEUED)
      Qyu.logger.debug "Task with ID=#{id} marked queued."
    end

    def mark_working
      Qyu.store.update_status(id, Status::WORKING)
      Qyu.logger.debug "Task with ID=#{id} marked working."
    end

    def mark_completed
      Qyu.store.update_status(id, Status::COMPLETED)
      Qyu.logger.info "Task with ID=#{id} marked completed."
    end

    def mark_failed
      Qyu.store.update_status(id, Status::FAILED)
      Qyu.logger.debug "Task with ID=#{id} marked failed."
    end

    def mark_invalid_payload
      Qyu.store.update_status(id, Status::INVALID_PAYLOAD)
      Qyu.logger.debug "Task with ID=#{id} has invalid payload."
    end

    def acknowledge_message
      fail Qyu::Errors::MessageNotReceived if message_id.nil?
      self.class.acknowledge_message(queue_name, message_id)
    end

    def self.acknowledge_message(queue_name, message_id)
      Qyu.logger.debug "Acknowledging message with ID=#{message_id} from queue `#{queue_name}`"
      Qyu.queue.acknowledge_message(queue_name, message_id)
    end

    def requeue
      # TODO For FIFO queues (future use)
      fail Qyu::Errors::MessageNotReceived if message_id.nil?
      self.class.acknowledge_message(queue_name, message_id)
      self.class.requeue(queue_name, id, message_id)
    end

    def self.requeue(queue_name, id, message_id)
      # TODO For FIFO queues (future use)
      Qyu.logger.debug "Re-enqueuing message with ID=#{message_id} in queue `#{queue_name}`"
      Qyu.queue.enqueue_task(queue_name, id)
    end

    def enqueue_in_failure_queue
      fail Qyu::Errors::MessageNotReceived if message_id.nil?
      self.class.acknowledge_message(queue_name, message_id)
      self.class.enqueue_in_failure_queue(queue_name, id, message_id)
    end

    def self.enqueue_in_failure_queue(queue_name, id, message_id)
      Qyu.logger.debug "Enqueuing failed message with ID=#{message_id} in #{queue_name} failures queue"
      Qyu.queue.enqueue_task_to_failed_queue(queue_name, id)
    end

    # Returns workflow specified in parent job
    #
    # @return [Qyu::Workflow] full workflow
    def workflow
      job.workflow
    end

    # Returns workflow descriptor from parent job
    #
    # @return [Hash] workflow descriptor
    def workflow_descriptor
      job.descriptor
    end

    # Returns parent job
    #
    # @return [Qyu::Job] parent job
    def job
      @job ||= Qyu::Job.find(job_id)
    end

    # Returns task descriptor
    #
    # @return [Hash] task descriptor
    def descriptor
      workflow_descriptor['tasks'][name]
    end

    def [](attribute)
      public_send(attribute)
    end

    private

    def initialize(id, attributes, queue_name, message_id = nil)
      # puts "task initialized attrs: #{attributes}"
      @status         = Status.new(id)
      @id             = id
      @job_id         = attributes['job_id']
      @parent_task_id = attributes['parent_task_id']
      @payload        = attributes['payload']
      @queue_name     = queue_name
      @message_id     = message_id
      @name           = attributes['name']
      @created_at     = attributes['created_at']
      @updated_at     = attributes['updated_at']

      @locked_until = nil
      @lease_thread = nil
      @lease_token  = nil
    end

    def schedule_renewal
      Qyu.logger.debug 'scheduling renewal'
      renewal_moment = Qyu::Utils.seconds_after_time(-1 * LEASE_PERCENTAGE_THRESHOLD_BEFORE_RENEWAL * Qyu.config.store[:lease_period], @locked_until)
      Qyu.logger.debug "renewal moment: #{renewal_moment}"
      @lease_thread = Thread.new do
        Qyu.logger.debug 'lease thread entered'
        while Time.now < renewal_moment
          sleep(POLL_INTERVAL)
          Qyu.logger.debug 'lease thread sleep'
        end
        Qyu.logger.debug 'lease thread time has come'
        @locked_until = Qyu.store.renew_lock_lease(id, Qyu.config.store[:lease_period], @lease_token)
        Qyu.logger.debug "lease thread locked until = #{@locked_until}"
        schedule_renewal
      end
    end
  end
end
