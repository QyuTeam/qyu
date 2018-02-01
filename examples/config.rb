# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
Bundler.setup

require 'qyu'

Qyu.configure(
  queue: {
    type: :memory
  },
  store: {
    type: :memory,
    lease_period: 60
  },
  logger: Logger.new(STDOUT)
)

Qyu.test_connections
