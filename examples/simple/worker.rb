# frozen_string_literal: true

require_relative '../config'

class SimpleWorker
  def initialize
    @worker = Qyu::Worker.new do
      callback :execute, :before do
        Qyu.logger.info 'Waiting for task..'
      end

      callback :execute, :after do
        Qyu.logger.info 'Done'
      end

      # Payload validation
      validates :times, presence: true, type: :integer
    end
  end

  def run
    # Consumes message from print-hello queue
    @worker.work('print-hello') do |task|
      task.payload['times'].times do |i|
        Qyu.logger.info "#{i + 1}. Hello"
      end
    rescue StandardError => ex
      Qyu.logger.error 'OMG :('
      Qyu.logger.error ex.message
    end
  end
end
