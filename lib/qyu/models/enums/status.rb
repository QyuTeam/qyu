# frozen_string_literal: true

module Qyu
  class Status
    COMPLETED       = 'completed'
    QUEUED          = 'queued'
    WORKING         = 'working'
    FAILED          = 'failed'
    INVALID_PAYLOAD = 'invalid_payload'

    def self.find(id)
      Qyu.store.find_task(id)
    end

    def initialize(id)
      @id = id
    end

    def status
      t = Qyu.store.find_task(@id)
      t['status']
    end

    def completed?
      status == COMPLETED
    end

    def queued?
      status == QUEUED
    end

    def working?
      status == WORKING
    end

    def failed?
      status == FAILED
    end

    def invalid_payload?
      status == INVALID_PAYLOAD
    end
  end
end
