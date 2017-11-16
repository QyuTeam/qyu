# frozen_string_literal: true

module Qyu
  class Factory
    class ServiceFactory
      class << self
        def register(adapter_class)
          types[adapter_class::TYPE] = adapter_class
        end

        def types
          @__types ||= {}
        end

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
