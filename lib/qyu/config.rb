# frozen_string_literal: true

module Qyu
  # Qyu::Config
  class Config
    attr_reader :queue, :store

    class ServiceConfig
      class << self
        # Register a service (Queue/Store)
        #
        # @param adapter_class [Class] service Class to Register
        # @return [Class] service Class to Register
        def register(adapter_class)
          types[adapter_class::TYPE] = adapter_class
        end

        # Validate provided config
        #
        # @param config [Hash] configuration
        # @return [Boolean]
        def valid?(config)
          types[config[:type]].valid_config?(config)
        end

        # Get registered services
        #
        # @return [Hash] registered services
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
