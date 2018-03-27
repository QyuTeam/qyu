# frozen_string_literal: true

require_relative '../../config'

class SplitArrayWorkerWithBlock
  def initialize
    @worker = Qyu::SplitWorker.new do
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
    end
  end

  def run
    # Consumes message from split-array queue
    @worker.work('split-array') do |task|
      # For example
      # Can get something from database
      # or preprocess data etc..
      @splittable = []
      @splittable.push(10)
      @splittable.push(9)
      @splittable.push(8)
      @splittable.push(7)
      @splittable.push(6)
      @splittable.push(5)
      @splittable.push(4)
      @splittable.push(3)
      @splittable.push(2)
      @splittable.push(1)
      @splittable.delete_if { |x| x < 3 }
      @splittable
    end
  end
end
