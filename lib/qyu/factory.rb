# frozen_string_literal: true

module Qyu
  # Qyu::Factory
  class Factory #:nodoc:
    class ServiceFactory
      class << self
        # Register a service (Queue/Store)
        #
        # @param adapter_class [Class] service Class to Register
        # @return [Class] service Class to Register
        def register(adapter_class)
          types[adapter_class::TYPE] = adapter_class
        end

        # Get registered services
        #
        # @return [Hash] registered services
        def types
          @__types ||= {}
        end

        # Initialize Queue/Store service with provided configuration
        #
        # @return [Object] an adapter
        def get(config)
          Qyu.logger.info "Got factory #{types[config[:type]]}"
          types[config[:type]].new(config)
        end
      end
    end

    class QueueFactory < ServiceFactory; end
    class StoreFactory < ServiceFactory; end
  end
end
