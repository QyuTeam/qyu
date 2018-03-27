# frozen_string_literal: true

require_relative '../config'

descriptor = {
  'starts' => %w(
    split:array
  ),
  'tasks' => {
    'split:array' => {
      'queue' => 'split-array',
      'starts_manually' => ['print:array'],
      'starts_with_params' => {
        'report:success' => {
          'nr_tasks' => {
            'count' => 'print:array'
          }
        }
      }
    },
    'print:array' => {
      'queue' => 'print-array'
    },
    'report:success' => {
      'queue' => 'report-success',
      'waits_for' => {
        'print:array' => {
          'condition' => {
            'param' => 'nr_tasks',
            'function' => 'eq_completed'
          }
        }
      }
    }
  }
}

name = 'split-n-sync'
Qyu.logger.info "Creating workflow #{name}"
Qyu::Workflow.create(name: name, descriptor: descriptor)
