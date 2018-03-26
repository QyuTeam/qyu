# frozen_string_literal: true

module Qyu
  # Qyu::Workflow
  class Workflow
    attr_reader :id, :name, :descriptor, :created_at, :updated_at

    class << self
      def create(name:, descriptor:)
        validator = Qyu::Concerns::WorkflowDescriptorValidator.new(descriptor)
        fail Qyu::Errors::WorkflowDescriptorValidatorationError, validator.errors unless validator.valid?
        id = persist(name, descriptor)
        time = Time.now
        new(id, name, descriptor, time, time)
      end

      def find(id, raise_error: true)
        workflow_attrs = Qyu.store.find_workflow(id)
        raise Qyu::Errors::WorkflowNotFound.new(:id, id) if workflow_attrs.nil? && raise_error
        return nil if workflow_attrs.nil?
        new(id, workflow_attrs['name'], workflow_attrs['descriptor'])
      end

      def find_by(name: nil, id: nil)
        return find_by_name(name) if name
        return find(id, raise_error: false) if id
      end

      def find_by!(name: nil, id: nil)
        workflow = find_by(name: name, id: id)
        raise Qyu::Errors::WorkflowNotFound.new(:id, id) if workflow.nil? && id
        raise Qyu::Errors::WorkflowNotFound.new(:id, id) if workflow.nil? && id
        workflow
      end

      def select(limit: 30, offset: 0, order: :asc)
        workflow_records = Qyu.store.select_workflows(limit, offset, order)
        workflow_records.map do |record|
          new(record['id'], record['name'], record['descriptor'])
        end
      end

      def delete(id)
        Qyu.store.delete_workflow(id)
      end

      def delete_by(name: nil, id: nil)
        raise ArgumentError, 'specify either name or id' if (name && id) || (name.nil? && id.nil?)
        Qyu.store.delete_workflow_by_name(name) if name
        delete(id) if id
      end

      def count
        Qyu.store.count_workflows
      end

      private

      def persist(name, descriptor)
        Qyu.store.persist_workflow(name, descriptor)
      end

      def find_by_name(name)
        workflow_attrs = Qyu.store.find_workflow_by_name(name)
        return nil unless workflow_attrs
        new(workflow_attrs['id'], workflow_attrs['name'], workflow_attrs['descriptor'])
      end
    end

    def [](attribute)
      public_send(attribute)
    end

    private_class_method :new

    private

    def initialize(id, name, descriptor, created_at = nil, updated_at = nil)
      @id = id
      @name = name
      @descriptor = descriptor
      @created_at = created_at
      @updated_at = updated_at
    end
  end
end
