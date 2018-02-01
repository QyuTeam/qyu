# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
Bundler.setup

require 'qyu'
logger = Logger.new(STDOUT)
logger.level = :info

Qyu.configure(
  queue: {
    type: :memory
  },
  store: {
    type: :memory,
    lease_period: 60
  },
  logger: logger
)

Qyu.test_connections
