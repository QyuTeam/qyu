require 'active_support'
require 'json'
require 'logger'
require 'time'
require 'securerandom'
require 'qyu/version'
require 'qyu/config'
require 'qyu/factory'
require 'qyu/utils'
require 'qyu/errors'
require 'qyu/models'
require 'qyu/queue'
require 'qyu/store'
require 'qyu/workers'

module Qyu
  class << self
    def configure(queue:, store:, logger: nil)
      self.config = Qyu::Config.new(
        queue: queue,
        store: store
      )
      self.logger = logger || default_logger unless defined?(@@__logger)
      self.test_connections
    end

    def config
      fail 'Undefined configuration' unless defined?(@@__config)

      @@__config
    end
    alias configuration config

    def configured?
      defined?(@@__config)
    end

    def logger=(logger)
      @@__logger = logger
    end

    def logger
      @@__logger ||= default_logger
    end

    def queue
      @@__queue ||= Qyu::Factory::QueueFactory.get(config.queue)
    end

    def store
      @@__store ||= Qyu::Factory::StoreFactory.get(config.store)
    end

    def test_connections
      queue
      store
    end

    private

    def config=(config)
      fail 'Can not re-define configuration' if configured?
      fail 'Invalid configuration' unless config.is_a?(Qyu::Config)

      @@__config = config
    end

    def default_logger
      logger = Logger.new(STDOUT)
      logger.level = Logger::DEBUG
      logger
    end
  end
end
