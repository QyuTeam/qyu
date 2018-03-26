# frozen_string_literal: true

module Qyu
  module Workers
    module Concerns
      # Qyu::Workers::Concerns::Callback
      #
      # Meant to add callbacks to Qyu::Worker
      #
      # Usage:
      #
      # Qyu::Worker.new do
      #   callback :execute, :after do
      #     # Do something after execution
      #   end
      # end
      #
      module Callback
        # Adds a callback option to worker
        #
        #   callback :execute, :after do
        #     # Do something after execution
        #   end
        #
        #   callback :execute, :before do
        #     # Do something before execution
        #   end
        #
        #   callback :execute, :around do
        #     # Do something around execution
        #   end
        #
        # @param [Symbol] just :execute for now
        # @param [Symbol] callback type
        # @param [block] block to execute as callback
        def callback(method, type, &block)
          @_callbacks ||= {}
          @_callbacks[method] ||= {}
          @_callbacks[method][type] = block
        end

        def run_callbacks(method, &block)
          find_callback(method, :before)&.call
          find_callback(method, :around) ? find_callback(method, :around).call(block) : yield
          find_callback(method, :after)&.call
        end

        private

        def find_callback(method, type)
          @_callbacks.dig(method, type) if @_callbacks.is_a?(Hash)
        end
      end
    end
  end
end
