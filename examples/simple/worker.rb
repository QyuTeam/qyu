# frozen_string_literal: true

require_relative '../config'

class SimpleWorker
  def initialize
    @worker = Qyu::Worker.new do
      callback :execute, :before do
        puts 'Starting'
      end

      callback :execute, :after do
        puts 'Done'
      end

      # Payload validation
      validates :times, presence: true, type: :integer
    end
  end

  def run
    # Consumes message from print-hello queue
    @worker.work('print-hello') do |task|
      task.payload['times'].times do |i|
        puts "#{i}. Hello"
      end
    rescue StandardError => ex
      puts 'OMG :('
      puts ex.message
    end
  end
end
