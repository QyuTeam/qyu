# frozen_string_literal: true

require 'qyu/workers/base'
require 'qyu/workers/sync'

Qyu::Worker = Qyu::Workers::Base
Qyu::SyncWorker = Qyu::Workers::Sync
