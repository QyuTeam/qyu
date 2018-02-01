# frozen_string_literal: true

require_relative '../config'

payload = { 'times' => 5 }
Qyu.logger.info "Enqueuing job with payload #{payload}"
job = Qyu::Job.create(workflow: 'say-hello', payload: payload)
job.start
