require 'bundler/setup'
require 'timecop'
require 'pry'
require 'pry-byebug'
require 'simplecov'
require 'qyu'

SimpleCov.start
RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    Qyu.__send__(:remove_class_variable, :@@__config) if Qyu.class_variable_defined?(:@@__config)
    Qyu.__send__(:remove_class_variable, :@@__queue) if Qyu.class_variable_defined?(:@@__queue)
    Qyu.__send__(:remove_class_variable, :@@__store) if Qyu.class_variable_defined?(:@@__store)
    sc = defined?(store_config) ? byebug && store_config : { type: :memory, lease_period: 60 }
    qc = defined?(queue_config) ? queue_config : { type: :memory }
    Qyu.config = Qyu::Config.new(queue: qc, store: sc)
  end
end
