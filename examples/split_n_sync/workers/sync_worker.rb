# frozen_string_literal: true

require_relative '../../config'

class SyncWorker
  def run
    # Consumes messages from split-array queue, checks whether all split tasks were finished
    # and if they are, executes a block
    Qyu::SyncWorker.new do
      callback :execute, :before do
        Qyu.logger.info 'Waiting for tasks to finish..'
      end

      work('report-success') do |task|
        Qyu.logger.info "Split tasks finished. Synced."
      end
    end
  end
end
