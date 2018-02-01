# frozen_string_literal: true

require_relative '../config'

descriptor = {
  'starts' => %w(
    print_hello
  ),
  'tasks' => {
    'print_hello' => {
      'queue' => 'print-hello'
    }
  }
}

name = 'say-hello'
Qyu.logger.info "Creating workflow #{name}"
Qyu::Workflow.create(name: name, descriptor: descriptor)
