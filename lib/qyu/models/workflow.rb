# frozen_string_literal: true

module Qyu
  class Workflow
    attr_reader :id, :name, :descriptor, :created_at, :updated_at

    def self.create(name:, descriptor:)
      validator = Qyu::Utils::WorkflowDescriptorValidatorator.new(descriptor)
      fail Qyu::Errors::WorkflowDescriptorValidatorationError, validator.errors unless validator.valid?
      id = persist(name, descriptor)
      time = Time.try(:zone) ? Time.zone.now : Time.now
      new(id, name, descriptor, time, time)
    end

    def self.find(id)
      workflow_attrs = Qyu.store.find_workflow(id)
      raise Qyu::Errors::WorkflowNotFound.new(:id, id) if workflow_attrs.nil?
      new(id, workflow_attrs['name'], workflow_attrs['descriptor'])
    end

    def self.find_by_name(name)
      workflow_attrs = Qyu.store.find_workflow_by_name(name)
      raise Qyu::Errors::WorkflowNotFound.new(:name, name) if workflow_attrs.nil?
      new(workflow_attrs['id'], workflow_attrs['name'], workflow_attrs['descriptor'])
    end

    def self.select(limit = 30, offset = 0, order = :asc)
      workflow_records = Qyu.store.select_workflows(limit, offset, order)
      workflow_records.map do |record|
        new(record['id'], record['name'], record['descriptor'])
      end
    end

    def self.count
      Qyu.store.count_workflows
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

    def self.persist(name, descriptor)
      Qyu.store.persist_workflow(name, descriptor)
    end
  end
end
