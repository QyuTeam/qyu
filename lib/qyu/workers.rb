# frozen_string_literal: true

require 'qyu/workers/concerns/callback'
require 'qyu/workers/concerns/failure_queue'
require 'qyu/workers/concerns/payload_validator'
require 'qyu/workers/base'
require 'qyu/workers/split'
require 'qyu/workers/sync'

Qyu::Worker = Qyu::Workers::Base
Qyu::SplitWorker = Qyu::Workers::Split
Qyu::SyncWorker = Qyu::Workers::Sync
