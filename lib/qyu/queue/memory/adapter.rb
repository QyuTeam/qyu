# frozen_string_literal: true

module Qyu
  module Queue
    module Memory
      # Qyu::Queue::Memory::Adapter
      class Adapter < Qyu::Queue::Base
        TYPE = :memory

        def initialize(_config)
          @temp_store = Hash.new(false)
          @queues = {}
          @threads = []
        end

        def self.valid_config?(_config)
          # TODO
          true
        end

        def enqueue_task(queue_name, task_id)
          queue(queue_name) << { 'task_id' => task_id }
        end

        def enqueue_task_to_failed_queue(queue_name, task_id)
          failed_queue_name = queue_name + '-failed'
          enqueue_task(failed_queue_name, task_id)
        end

        # fetch_next_message
        #
        # @param [String] queue_name
        # @return [Hash] the acknowledge message
        #
        # TODO Note the uglyness in `while ... empty?`; it's because of reasons
        # mainly for this (http://stackoverflow.com/q/11660253) reason.
        def fetch_next_message(queue_name)
          sleep(1) while queue(queue_name).empty?
          message = queue(queue_name).pop(true)
          message_id = Qyu::Utils.uuid
          schedule_requeue(message, message_id, queue_name)
          {
            'id' => message_id,
            'task_id' => message['task_id']
          }
        end

        def acknowledge_message(_queue_name, message_id)
          @temp_store[message_id] = true
        end

        def queues
          @queues.map do |name, queue|
            { name: name, messages: queue&.size }
          end
        end

        def size(queue_name)
          queue(queue_name).size
        end

        private

        def schedule_requeue(message, message_id, queue_name)
          @threads << Thread.new(message_id, message) do |t_message_id, t_message|
            sleep(5)
            queue(queue_name) << t_message unless message_acknowledged?(t_message_id)
          end
        end

        def message_acknowledged?(message_id)
          @temp_store[message_id] == true
        end

        # queue, or "get_or_create_queue"
        #
        # @param [String] name The name of the queue to create if it does
        #    does not exist and return;
        def queue(name)
          if @queues[name]
            Qyu.logger.debug "Queue `#{name}`: #{@queues[name].length} elements"
            return @queues[name]
          end
          Qyu.logger.info "Could not find queue `#{name}`, creating it"
          @queues[name] ||= ::Queue.new
        end
        alias get_or_create_queue queue
      end
    end
  end
end
