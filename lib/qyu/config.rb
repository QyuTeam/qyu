# frozen_string_literal: true

module Qyu
  # Qyu::Config
  class Config
    attr_reader :queue, :store

    class ServiceConfig
      class << self
        def register(adapter_class)
          types[adapter_class::TYPE] = adapter_class
        end

        def valid?(config)
          types[config[:type]].valid_config?(config)
        end

        def types
          @__types ||= {}
        end
      end
    end

    class QueueConfig < ServiceConfig; end
    class StoreConfig < ServiceConfig; end

    def initialize(queue:, store:)
      fail 'Invalid message queue configuration' unless QueueConfig.valid?(queue)
      fail 'Invalid state store configuration' unless StoreConfig.valid?(store)

      @queue = queue
      @store = store
    end
  end
end
