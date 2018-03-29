# frozen_string_literal: true

RSpec.describe Qyu::SplitWorker do
  let(:queue_name) { 'build-campaign' }
  let(:descriptor) do
    {
      'starts' => [
        'build:campaign'
      ],
      'tasks' => {
        'build:campaign' => {
          'queue' => queue_name,
          'starts_parallel' => ['build:single:language'],
        },
        'build:single:language' => {
          'queue' => 'build-language'
        },
        'build:sync' => {
          'waits_for' => {
            'build:single:language' => {
              'condition' => {
                'param' => 'nr_tasks',
                'function' => 'eq_completed'
              }
            }
          },
          'queue' => 'build-sync'
        }
      }
    }
  end

  let(:workflow_name) { 'build:generation' }
  let(:workflow) { Qyu::Workflow.create(name: workflow_name, descriptor: descriptor) }
  let(:payload) { { languages: languages } }
  let(:job) { Qyu::Job.create(workflow: workflow, payload: payload) }
  let(:languages) { ['ar', 'de', 'en', 'nl', 'zh'] }
  let(:size) { 1 }
  let(:split_worker) do
    Qyu::SplitWorker.new do
      validates :languages, presence: true, type: :array
      slice_size 1
      payload_key 'languages'
    end
  end

  before do
    job.start
  end

  describe '#work' do
    it 'continues execution' do
      expect do
        split_worker.work(queue_name, blocking: false)
        sleep 5
      end.
        to change { Qyu::Task.select(job_id: job.id).map(&:name).last }.
        from('build:campaign').
        to(Qyu::Status::COMPLETED)
    end
  end
end
