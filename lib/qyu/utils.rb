# frozen_string_literal: true

module Qyu
  module Utils
    def self.seconds_after_time(seconds, start_time = Time.now)
      start_time + seconds
    end

    def self.uuid
      SecureRandom.uuid
    end

    def self.stringify_hash_keys(object)
      object.map { |k, v| [k.to_s, v] }.to_h
    end
  end
end
