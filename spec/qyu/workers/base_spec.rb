# frozen_string_literal: true

RSpec.describe Qyu::Worker do
  let(:queue_name) { 'build-campaign' }
  let(:descriptor) do
    {
      'starts' => [
        'build:campaign'
      ],
      'tasks' => {
        'build:campaign' => {
          'queue' => queue_name,
          'starts_manually' => ['build:single:language'],
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
  let(:payload) { {} }
  let(:job) { Qyu::Job.create(workflow: workflow, payload: payload) }
  let!(:task) do
    Qyu::Task.create(
      queue_name: queue_name,
      attributes: {
        'job_id' => job.id,
        'payload' => payload,
        'parent_task_id' => nil,
        'name' => 'build:campaign'
      }
    )
  end

  describe '#work' do
    context 'when task can be fetched' do
      before do
        allow(Qyu::Task).to receive(:fetch).with(queue_name).and_return(task)
      end

      context 'when the task is not yet completed' do
        context 'when the lock can be acquired' do
          context 'when there is not no exception occuring during the process' do
            it 'does the right things' do
              value = 0
              expect(task).to receive(:acknowledgeable?).and_return(false)
              expect(task).to receive(:lock!).and_return(true)
              expect(task).to receive(:mark_working)
              allow(task).to receive(:job).and_return(job)
              expect(job).to receive(:create_next_tasks).with(task, {})
              expect(task).to receive(:unlock!)
              expect(task).to receive(:mark_completed)
              expect(task).to receive(:acknowledge_message)
              Qyu::Worker.new.work('build-campaign', blocking: false) do |_t|
                value += 1
              end
              expect(value).to be == 1
            end
          end

          context 'when there is an exception occuring during the process' do
            context 'if failure_queue is set to true' do
              let(:worker) do
                Qyu::Worker.new do
                  failure_queue true
                end
              end

              it 'does the right things' do
                value = 0
                expect(task).to receive(:acknowledgeable?).and_return(false)
                expect(task).to receive(:lock!).and_return(true)
                expect(task).to receive(:mark_working)
                expect(task).to receive(:enqueue_in_failure_queue)
                expect(task).to receive(:unlock!)
                expect(task).to receive(:mark_queued)
                worker.work('build-campaign', blocking: false) do |_t|
                  fail 'Going south'
                  value += 1
                end
                expect(value).to be == 0
              end
            end

            context 'if failure_queue is set to false' do
              let(:worker) do
                Qyu::Worker.new do
                  failure_queue false
                end
              end

              it 'does the right things' do
                value = 0
                expect(task).to receive(:acknowledgeable?).and_return(false)
                expect(task).to receive(:lock!).and_return(true)
                expect(task).to receive(:mark_working)
                expect(task).to receive(:unlock!)
                expect(task).to receive(:mark_queued)
                worker.work('build-campaign', blocking: false) do |_t|
                  fail 'Going south'
                  value += 1
                end
                expect(value).to be == 0
              end
            end
          end

          context 'when there are validations' do
            let(:validation_options) { { presence: true, type: :integer, unless: :account_id } }
            let(:worker) do
              v = validation_options
              Qyu::Worker.new do
                validates :user_id, v
              end
            end

            context 'when validations pass' do
              let(:payload) { { user_id: 1 } }

              it 'continues execution' do
                expect do
                  worker.work('build-campaign', blocking: false) do |_t|
                    42
                  end
                end.
                  to change { task.status.status }.
                  from(Qyu::Status::QUEUED).
                  to(Qyu::Status::COMPLETED)
              end
            end

            context 'when validation is conditional' do
              context 'when unless passes' do
                let(:payload) { { account_id: 1 } }

                it 'continues execution' do
                  expect do
                    worker.work('build-campaign', blocking: false) do |_t|
                      42
                    end
                  end.
                    to change { task.status.status }.
                    from(Qyu::Status::QUEUED).
                    to(Qyu::Status::COMPLETED)
                end
              end

              context 'when if passes' do
                let(:validation_options) { { presence: true, type: :integer, if: :account_id } }
                let(:payload) { { user_id: 1, account_id: 1 } }

                it 'continues execution' do
                  expect do
                    worker.work('build-campaign', blocking: false) do |_t|
                      42
                    end
                  end.
                    to change { task.status.status }.
                    from(Qyu::Status::QUEUED).
                    to(Qyu::Status::COMPLETED)
                end
              end

              context 'when if fails' do
                let(:validation_options) { { presence: true, type: :integer, if: :account_id } }
                let(:payload) { { account_id: 1 } }

                it 'continues execution' do
                  expect do
                    worker.work('build-campaign', blocking: false) do |_t|
                      42
                    end
                  end.
                    to change { task.status.status }.
                    from(Qyu::Status::QUEUED).
                    to(Qyu::Status::INVALID_PAYLOAD)
                end
              end
            end

            context 'when type validation fails' do
              let(:payload) { {} }

              it 'fails task' do
                expect do
                  worker.work('build-campaign', blocking: false) do |_t|
                    42
                  end
                end.
                  to change { task.status.status }.
                  from(Qyu::Status::QUEUED).
                  to(Qyu::Status::INVALID_PAYLOAD)
              end
            end
          end
        end

        context 'when the lock cannot be acquired' do
          it 'does nothing' do
            value = 0
            expect(task).to receive(:acknowledgeable?).and_return(false)
            expect(task).to receive(:lock!).and_return(false)
            Qyu::Worker.new.work('build-campaign', blocking: false) do |_t|
              value += 1
            end
            expect(value).to be == 0
          end
        end
      end

      context 'when the task is already completed' do
        it 'acknowledges the message' do
          value = 0
          expect(task).to receive(:acknowledgeable?).and_return(true)
          expect(task).to receive(:acknowledge_message)
          Qyu::Worker.new.work('build-campaign', blocking: false) do |_t|
            value += 1
          end
          expect(value).to be == 0
        end
      end
    end

    context 'when a Task cannot be fetched' do
      context 'when the Task cannot be retrieved from the StateStore' do
        let(:message_id) { 'random_message_id' }
        let(:task_id) { 'random_task_id' }
        let(:original_error) do
          original_error = nil
          begin
            fail 'message'
          rescue => ex
            original_error = ex
          end
          original_error
        end

        before do
          allow(Qyu::Task).
            to receive(:fetch).
            with(queue_name).
            and_raise Qyu::Errors::CouldNotFetchTask.new(queue_name, message_id, task_id, original_error)
        end

        it 'does not acknowledge the message' do
          expect(Qyu::Task).not_to receive(:acknowledge_message)
          value = 0
          Qyu::Worker.new.work('build-campaign', blocking: false) do |_t|
            value += 1
          end
          expect(value).to be == 0
        end
      end

      context 'when the Task does not exist in the StateStore' do
        let(:message_id) { 'random_message_id' }
        let(:task_id) { 'random_task_id' }
        let(:original_error) do
          original_error = nil
          begin
            fail Qyu::Errors::TaskNotFound.new(task_id, RuntimeError.new('message'))
          rescue => ex
            original_error = ex
          end
          original_error
        end

        before do
          allow(Qyu::Task).
            to receive(:fetch).
            with(queue_name).
            and_raise Qyu::Errors::CouldNotFetchTask.new(queue_name, message_id, task_id, original_error)
        end

        it 'acknowledges the message' do
          expect(Qyu::Task).to receive(:acknowledge_message).with(queue_name, message_id)
          value = 0
          Qyu::Worker.new.work('build-campaign', blocking: false) do |_t|
            value += 1
          end
          expect(value).to be == 0
        end
      end

      context 'when there are issues connecting to the message queue' do
        let(:original_error) do
          original_error = nil
          begin
            fail 'message'
          rescue => ex
            original_error = ex
          end
          original_error
        end

        before do
          allow(Qyu::Task).
            to receive(:fetch).
            with(queue_name).
            and_raise Qyu::Errors::CouldNotFetchTask.new(queue_name, nil, nil, original_error)
        end

        it 'it does not do anything - will retry next time' do
          value = 0
          Qyu::Worker.new.work('build-campaign', blocking: false) do |_t|
            value += 1
          end
          expect(value).to be == 0
        end
      end
    end
  end
end
