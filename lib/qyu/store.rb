require 'qyu/store/base'
require 'qyu/store/memory/adapter'

Qyu::Config::StoreConfig.register(Qyu::Store::Memory::Adapter)
Qyu::Factory::StoreFactory.register(Qyu::Store::Memory::Adapter)
