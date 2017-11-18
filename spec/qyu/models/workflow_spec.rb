# frozen_string_literal: true

RSpec.shared_examples 'workflow' do
  let(:workflow_name) { 'sample-workflow' }
  let(:descriptor) do
    {
      'starts' => [
        'variation_generation'
      ],
      'tasks' => {
        'variation_generation' => {
          'queue' => 'var_gen',
          'starts' => ['variation_scraping']
        },
        'variation_scraping' => {
          'queue' => 'var_scr'
        }
      }
    }
  end

  let(:workflow) { Qyu::Workflow.create(name: workflow_name, descriptor: descriptor) }
end

RSpec.describe Qyu::Workflow do
  describe 'InMemoryAdapter' do
    let(:store_config) { { type: :memory, lease_period: 60 } }
    include_examples 'workflow'
  end
end
