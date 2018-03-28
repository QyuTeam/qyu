# frozen_string_literal: true

require_relative '../../config'

class PrintWorker
  def run
    Qyu::Worker.new do
      callback :execute, :before do
        Qyu.logger.info 'Waiting for task..'
      end

      callback :execute, :after do
        Qyu.logger.info 'Printed'
      end

      # Payload validation
      validates :array, presence: true, type: :array

      # Consumes messages from split-array queue and executes a block of code
      work('print-array') do |task|
        arr = task.payload['array']
        Qyu.logger.debug "[Task##{task.id}] received array: #{arr}"
        arr.each.with_index do |element, index|
          Qyu.logger.info "[Task##{task.id}] #{index + 1}. #{element}"
        end
      end
    end
  end
end
