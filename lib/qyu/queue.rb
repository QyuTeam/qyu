require 'qyu/queue/base'
require 'qyu/queue/memory/adapter'

Qyu::Config::QueueConfig.register(Qyu::Queue::Memory::Adapter)
Qyu::Factory::QueueFactory.register(Qyu::Queue::Memory::Adapter)
