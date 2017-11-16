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
    def config=(config)
      fail 'Can not re-define configuration' if defined?(@@__config)
      fail 'Invalid configuration' unless config.is_a?(Qyu::Config)

      @@__config = config
    end

    def config
      fail 'Undefined configuration' unless defined?(@@__config)

      @@__config
    end

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

    def default_logger
      logger = Logger.new(STDOUT)
      logger.level = Logger::DEBUG
      logger
    end
  end
end
