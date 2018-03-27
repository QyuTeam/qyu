# frozen_string_literal: true

require_relative '../config'

payload = { 'array' => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] }
Qyu.logger.info "Enqueuing job with payload #{payload}"
job = Qyu::Job.create(workflow: 'split-n-sync', payload: payload)
job.start
