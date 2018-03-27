# frozen_string_literal: true

require_relative '../../config'

class SyncWorker
  def initialize
    @worker = Qyu::SyncWorker.new
  end

  def run
    # Consumes message from split-array queue
    @worker.work('report-success') do |task|
      Qyu.logger.info "Done!"
    end
  end
end
