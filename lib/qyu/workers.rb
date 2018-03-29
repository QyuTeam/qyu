# frozen_string_literal: true

(
  Dir["#{File.dirname(__FILE__)}/workers/concerns/*.rb"]
).each do |path|
  require path
end

module Qyu
  module Workers
    autoload :Base,   'qyu/workers/base'
    autoload :Split,  'qyu/workers/split'
    autoload :Sync,   'qyu/workers/sync'
  end

  Worker      = Qyu::Workers::Base
  SplitWorker = Qyu::Workers::Split
  SyncWorker  = Qyu::Workers::Sync
end
