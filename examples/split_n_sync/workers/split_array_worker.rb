# frozen_string_literal: true

require_relative '../../config'

class SplitArrayWorker
  def run
    Qyu::SplitWorker.new do
      callback :execute, :before do
        Qyu.logger.info 'Waiting for task..'
      end

      callback :execute, :after do
        Qyu.logger.info 'Split'
      end

      # Payload validation
      validates :array, presence: true, type: :array

      # Slice size
      slice_size 3

      # Variable name with array to create new payload with
      payload_key 'array'

      # Consumes messages from split-array queue
      work 'split-array'
    end
  end
end
