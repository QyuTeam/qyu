# frozen_string_literal: true

RSpec.describe Qyu::Concerns::WorkflowDescriptorValidator do
  let(:subject) { Qyu::Concerns::WorkflowDescriptorValidator.new(descriptor) }

  describe '#valid?' do
    context 'when it is a simple workflow' do
      let(:descriptor) do
        {
          'starts' => [
            'keywork:generation'
          ],
          'tasks' => {
            'keywork:generation' => {
              'queue' => 'keyword_generation',
              'starts' => ['keywork:sanitization']
            },
            'keywork:sanitization' => {
              'queue' => 'keyword_sanitization'
            }
          }
        }
      end

      it 'returns true' do
        expect(subject.valid?).to eq(true)
      end
    end

    context 'when it is a split and sync workflow' do
      let(:descriptor) do
        {
          'starts' => %w(
            split:array
          ),
          'tasks' => {
            'split:array' => {
              'queue' => 'split-array',
              'starts_parallel' => ['print:array'],
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
      end

      it 'returns true' do
        expect(subject.valid?).to eq(true)
      end
    end

    context 'when a queue name is missing' do
      let(:descriptor) do
        {
          'starts' => ['task:name'],
          'tasks' => {
            'task:name' => {
              'queue' => 'something',
              'starts' => ['s:1', 's:2']
            },
            's:1' => {
              'queue' => 's1'
            },
            's:2' => {
              # missing queue name
            }
          }
        }
      end

      it 'returns false' do
        expect(subject.valid?).to eq(false)
      end
    end

    context 'when some referenced tasks do not exist' do
      let(:descriptor) do
        {
          'starts' => ['task:name'],
          'tasks' => {
            'task:name' => {
              'queue' => 'something',
              'starts' => ['s:1', 's:2']
            },
            's:1' => {
              'queue' => 's1'
            }
            # s:2 is missing
          }
        }
      end

      it 'returns false' do
        expect(subject.valid?).to eq(false)
      end
    end
  end
end
