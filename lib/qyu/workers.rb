# frozen_string_literal: true

(
  Dir["#{File.dirname(__FILE__)}/workers/concerns/*.rb"] +
  Dir["#{File.dirname(__FILE__)}/workers/*.rb"]
).each do |path|
  require path
end


Qyu::Worker = Qyu::Workers::Base
Qyu::SplitWorker = Qyu::Workers::Split
Qyu::SyncWorker = Qyu::Workers::Sync
