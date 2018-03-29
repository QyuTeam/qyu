# frozen_string_literal: true

module Qyu
  module Concerns
    # Qyu::Concerns::WorkflowDescriptorValidator
    class WorkflowDescriptorValidator
      # TODO: starts_parallel is a the same as starts_manually. The latter will be removed in Qyu v2
      ALLOWED_KEYS = %w(queue waits_for starts starts_parallel starts_manually starts_with_params).freeze
      DEPRECATED_KEYS = %(starts_manually)

      attr_reader :errors

      def initialize(descriptor)
        @descriptor = descriptor
        @errors = []
      end

      # validates a workflow's descriptor
      #
      # @return [Boolean]
      def valid?
        validate
        @errors.empty?
      end

      def validate
        @errors << 'Descriptor type must be a Hash.' unless validate_descriptor_type
        @errors << 'Entry points (starts) must be an Array.' unless validate_entry_points_type
        @errors << 'Tasks must be a Hash.' unless validate_tasks_type
        unless validate_entry_points_presence
          @errors << 'There must be at least 1 entry point, and all entry points must exist in the tasks Hash.'
        end
        @errors << 'There must be at least 1 task in the tasks Hash.' unless validate_tasks_presence

        tasks.keys.each do |task_name|
          unless validate_queue_presence(task_name)
            @errors << "#{task_name} must have a valid queue"
          end
          unless validate_task_keys(task_name)
            @errors << "#{task_name} must only contain the following keys: #{ALLOWED_KEYS}"
          end
          unless validate_task_reference_formats(task_name)
            @errors << "#{task_name} must follow the reference declaration format"
          end
          unless validate_referenced_tasks(task_name)
            @errors << "#{task_name} must list existing tasks in its references"
          end
          unless validate_sync_condition_params(task_name)
            @errors << "#{task_name} must pass the correct parameters to the sync task"
          end
        end
      rescue => ex
        Qyu.logger.error "Error while validation: #{ex.class}: #{ex.message}"
        Qyu.logger.error "Backtrace: #{ex.backtrace.join("\n")}"
        @errors << "#{ex.class}: #{ex.message}"
      end

      private

      def validate_descriptor_type
        @descriptor.is_a?(Hash)
      end

      def validate_entry_points_type
        entry_points.is_a?(Array)
      end

      def validate_tasks_type
        tasks.is_a?(Hash)
      end

      def validate_entry_points_presence
        !entry_points.empty? && \
          entry_points.all? { |task_name| tasks.keys.include?(task_name) }
      end

      def validate_tasks_presence
        !tasks.empty?
      end

      def validate_queue_presence(task_name)
        tasks[task_name]['queue'].is_a?(String)
      end

      def validate_task_keys(task_name)
        tasks[task_name].keys.all? { |key| ALLOWED_KEYS.include?(key) }
      end

      def validate_task_reference_formats(task_name)
        validate_format(task_name, 'starts', Array) &&
        validate_format(task_name, 'starts_parallel', Array) &&
        validate_format(task_name, 'starts_manually', Array) &&
        validate_format(task_name, 'starts_with_params', Hash) &&
        validate_format(task_name, 'waits_for', Hash)
      end

      def validate_referenced_tasks(task_name)
        validate_presence_of_reference_tasks(task_name, 'starts', Array) &&
        validate_presence_of_reference_tasks(task_name, 'starts_parallel', Array) &&
        validate_presence_of_reference_tasks(task_name, 'starts_manually', Array) &&
        validate_presence_of_reference_tasks(task_name, 'starts_with_params', Hash) &&
        validate_presence_of_reference_tasks(task_name, 'waits_for', Hash)
      end

      def validate_sync_condition_params(task_name)
        return true unless tasks[task_name]['starts_with_params']
        tasks[task_name]['starts_with_params'].all? do |started_task_name, params_config|
          params_config.all? do |param_name, _param_config|
            tasks[started_task_name]['waits_for'].detect do |_t_name, sync_config|
              sync_config['condition']['param'] == param_name
            end
          end
        end
      end

      # checks whether a task reference key is present and in valid format
      #
      # @param task_name [String] name of task currently being validated
      # @param reference_key [String] reference key to validate tasks in it
      # @param klass [Class] class to validate against
      # @return [Boolean]
      def validate_format(task_name, reference_key, klass)
        (tasks[task_name][reference_key].nil? || tasks[task_name][reference_key].is_a?(klass))
      end

      # validates that a task descriptor is present and is a Hash
      #
      # @param task_name [String] name of task currently being validated
      # @param reference_key [String] reference key to validate tasks in it
      # @param klass [Class] how this reference key is represented
      # @return [Boolean]
      def validate_presence_of_reference_tasks(task_name, reference_key, klass)
        task_names = (tasks[task_name][reference_key] || klass.new)
        task_names = task_names.keys if klass.eql?(Hash)
        task_names.all? { |t_name| tasks[t_name].is_a?(Hash) }
      end

      def entry_points
        @descriptor['starts']
      end

      def tasks
        @descriptor['tasks']
      end
    end
  end
end
