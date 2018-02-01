# frozen_string_literal: true

module Qyu
  module Workers
    class Base
      include Concerns::Callback
      include Concerns::PayloadValidator
      include Concerns::FailureQueue

      attr_reader :id
      attr_accessor :processed_tasks

      def initialize(&block)
        @id = Qyu::Utils.uuid
        @processed_tasks = 0
        instance_exec(&block) if block_given?
      end

      def work(queue_name, blocking: true)
        log(:info, "Worker started for queue '#{queue_name}'")
        repeat = true

        while repeat
          run_callbacks(:execute) do
            begin
              fetched_task = fetch_task(queue_name)
              validate_payload!(fetched_task)
              log(:info, "Worker processed #{processed_tasks} tasks from queue `#{queue_name}`")
              if fetched_task.acknowledgeable?
                discard_completed_task(fetched_task)
              elsif fetched_task.lock!
                fetched_task.mark_working
                begin
                  yield(fetched_task)
                  conclude_task(fetched_task)
                rescue => ex
                  fail_task(fetched_task, ex)
                end
              end
            rescue Qyu::Errors::UnsyncError
            rescue Qyu::Errors::CouldNotFetchTask => ex
              acknowledge_message_with_task_id_not_found_in_store(ex)
            rescue Qyu::Errors::PayloadValidationError
              fetched_task.mark_invalid_payload
            rescue => ex
              log("Worker error: #{ex.class}: #{ex.message}")
              log("Backtrace: #{ex.backtrace.join("\n")}")
            end
          end

          repeat = blocking
          run_garbage_collector
        end
      end

      private

      def fetch_task(queue_name)
        fetched_task = Qyu::Task.fetch(queue_name)
        @processed_tasks += 1
        fetched_task
      end

      def discard_completed_task(fetched_task)
        log(:debug, 'Fetched completed task. Discarding...')
        fetched_task.acknowledge_message
      end

      def conclude_task(fetched_task)
        Qyu.store.transaction do
          log(:debug, 'Task finished. Creating next tasks.')
          fetched_task.job.create_next_tasks(
            fetched_task,
            fetched_task.job.payload.merge(fetched_task.payload)
          )
          fetched_task.unlock!
          fetched_task.mark_completed
        end
        fetched_task.acknowledge_message
      end

      def fail_task(fetched_task, exception)
        unless exception.class == Qyu::Errors::UnsyncError
          log("Worker error: #{exception.class}: #{exception.message}")
          log("Backtrace: #{exception.backtrace.join("\n")}")
        end
        Qyu.store.transaction do
          fetched_task.enqueue_in_failure_queue if @failure_queue
          fetched_task.unlock!
          fetched_task.mark_queued
        end
      end

      def acknowledge_message_with_task_id_not_found_in_store(exception)
        # If a task is not found in the Store then there is no point attempting
        # to fetch the message over and over again.
        log("Worker error: #{exception.class}: #{exception.message}")
        log("Backtrace: #{exception.backtrace.join("\n")}")
        log("Original error: #{exception.original_error.class}: #{exception.original_error.message}")
        log("Backtrace: #{exception.original_error.backtrace.join("\n")}")
        if exception.original_error.class == Qyu::Errors::TaskNotFound &&
           exception.queue_name &&
           exception.message_id
          Qyu::Task.acknowledge_message(exception.queue_name, exception.message_id)
        end
      end

      def log(level = :error, message)
        Qyu.logger.public_send(level, "[#{id}] #{message}")
      end

      def run_garbage_collector
        log(:debug, 'Running garbage collector')
        GC.start
      end
    end
  end
end
