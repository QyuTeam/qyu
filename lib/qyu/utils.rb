# frozen_string_literal: true

module Qyu
  # Qyu::Utils
  module Utils
    # Calculates end time after a number of seconds
    #
    # @param seconds [Integer] number of seconds after time
    # @param start_time [Time] time to start from
    # @return [Time] end time
    def self.seconds_after_time(seconds, start_time = Time.now)
      start_time + seconds
    end

    # Generates a unique UUID
    #
    # @return [String] UUID
    def self.uuid
      SecureRandom.uuid
    end

    # Convert all hash keys to strings
    #
    # @param object [Hash] Hash to stringify its keys
    # @return [String] Hash with string keys
    def self.stringify_hash_keys(object)
      object.map { |k, v| [k.to_s, v] }.to_h
    end
  end
end
