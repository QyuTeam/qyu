# frozen_string_literal: true

RSpec.shared_examples 'task' do
  describe 'create' do
    context 'when attributes are invalid' do
      let(:queue_name) { 'my_queue' }
      let(:attributes) { { 'test' => true } }

      before do
        expect(Qyu::Task).to receive(:valid_attributes?).with(attributes).and_return false
      end

      it 'raises exception' do
        expect { Qyu::Task.create(queue_name: queue_name, attributes: attributes) }.
          to raise_error Qyu::Errors::InvalidTaskAttributes
      end
    end

    context 'when queue name is invalid' do
      let(:queue_name) { nil }
      let(:attributes) { { test: true } }

      before do
        expect(Qyu::Task).to receive(:valid_attributes?).with(attributes).and_return true
        expect(Qyu::Task).to receive(:valid_queue_name?).with(queue_name).and_return false
      end

      it 'raises exception' do
        expect { Qyu::Task.create(queue_name: queue_name, attributes: attributes) }.
          to raise_error Qyu::Errors::InvalidQueueName
      end
    end

    context 'when inputs are valid' do
      let(:queue_name) { 'my_queue' }
      let(:attributes) { { 'payload' => { 'test' => true } } }

      it 'persists the Task in the StateStore' do
        id = Qyu::Task.create(queue_name: queue_name, attributes: attributes).id
        expect(Qyu.store.find_task(id)['payload']).to eq attributes['payload']
      end

      it 'enqueues the task id in the MessageQueue' do
        id = Qyu::Task.create(queue_name: queue_name, attributes: attributes).id
        expect(Qyu.queue.fetch_next_message(queue_name)['task_id']).to eq id
      end
    end

    context 'when a Task already exists with the same name, payload and job_id' do
      let(:descriptor) do
        { 'starts' => ['task'], 'tasks' => { 'task' => { 'queue' => 'something' } } }
      end
      let(:queue_name) { 'my_queue' }
      let(:workflow) { Qyu::Workflow.create(name: 'sample-workflow', descriptor: descriptor) }
      let(:job) { Qyu::Job.create(workflow: workflow, payload: {}) }
      let(:attributes) do
        {
          'name' => 'my_task',
          'payload' => { 'first_key' => 'first_val', 'second_key' => 'second_value' },
          'job_id' => job.id
        }
      end
      context 'when queue name is different' do
        let(:queue_name2) { 'my_other_queue' }
        it 'creates a new job' do
          expect(Qyu::Task.create(queue_name: queue_name, attributes: attributes).id).
            not_to eq Qyu::Task.create(queue_name: queue_name2, attributes: attributes).id
        end
      end
      context 'when queue name is the same' do
        it 'does not recreate the Task in the StateStore' do
          expect(Qyu::Task.create(queue_name: queue_name, attributes: attributes).id).
            to eq Qyu::Task.create(queue_name: queue_name, attributes: attributes).id
        end
      end
    end
  end

  describe 'fetch' do
    context 'when queue name is invalid' do
      let(:queue_name) { nil }

      it 'raises exception' do
        expect { Qyu::Task.fetch(queue_name) }.to raise_error Qyu::Errors::InvalidQueueName
      end
    end

    context 'when input is valid' do
      let(:queue_name) { 'my_queue' }
      let(:attributes) { { 'payload' => { 'test' => true } } }

      before do
        Qyu::Task.create(queue_name: queue_name, attributes: attributes)
      end

      it 'returns a task which is the first on the queue' do
        expect(Qyu::Task.fetch(queue_name).payload).to eq attributes['payload']
      end
    end
  end

  describe 'lock!' do
    let(:queue_name) { 'my_queue' }
    let(:attributes) { { 'payload' => { 'test' => true } } }
    let(:task) { Qyu::Task.create(queue_name: queue_name, attributes: attributes) }
    # like in the case of double delivery
    let!(:duplicate_task) { task.dup }

    context 'when the task is not locked' do
      it 'locks the task' do
        task.lock!
        expect(task.locked?).to eq true
      end
    end

    context 'when trying to lock the same task instance twice' do
      it 'raises an exception' do
        task.lock!
        expect { task.lock! }.to raise_error Qyu::Errors::LockAlreadyAcquired
      end
    end

    context 'when trying to lock the same task from a different instance' do
      it 'does not get the lock' do
        task.lock!
        expect(duplicate_task.lock!).to eq false
      end
    end

    context 'when the lease renewal mechanism fails' do
      it 'loses the lock after the lease period ends' do
        expect(task).to receive(:schedule_renewal)
        task.lock!
        expect(task.locked?).to eq true

        ten_seconds_after_lease_ends = Qyu::Utils.seconds_after_time(
                                        Qyu.config.store[:lease_period] + 10
                                      )
        Timecop.travel(ten_seconds_after_lease_ends) do
          expect(task.locked?).to eq false
        end
      end
    end

    context 'when the task is kept locked for more than the lease period' do
      it 'renews the lease' do
        task.lock!
        expect(task.locked?).to eq true

        renewal_window = Qyu::Utils.seconds_after_time(
                          Qyu.config.store[:lease_period] *
                          Qyu::Task::LEASE_PERCENTAGE_THRESHOLD_BEFORE_RENEWAL
                        )
        ten_seconds_after_lease_ends = Qyu::Utils.seconds_after_time(
                                        Qyu.config.store[:lease_period] + 10
                                      )

        # enter the renewal window artificially
        Timecop.travel(renewal_window) do
          sleep(Qyu::Task::POLL_INTERVAL * 4)
          expect(task.locked?).to eq true
        end

        Timecop.travel(ten_seconds_after_lease_ends) do
          expect(task.locked?).to eq true
        end
      end
    end

    context '#requeue' do
      let(:task_with_message_id) { Qyu::Task.fetch(queue_name) }

      it 're enqueues task' do
        task_with_message_id.acknowledge_message
        # Message dequeued
        task_with_message_id.requeue
        expect(Qyu.queue.fetch_next_message(queue_name)['task_id']).
          to eq task_with_message_id.id
      end
    end

    context '#enqueue_in_failure_queue' do
      let(:task_with_message_id) { Qyu::Task.fetch(queue_name) }
      let(:failure_queue_name) { queue_name + '-failed' }

      it 're enqueues task' do
        task_with_message_id.acknowledge_message
        # Message dequeued
        task_with_message_id.enqueue_in_failure_queue
        expect(Qyu.queue.fetch_next_message(failure_queue_name)['task_id']).
          to eq task_with_message_id.id
      end
    end
  end

  describe 'unlock!' do
    let(:queue_name) { 'my_queue' }
    let(:attributes) { { 'payload' => { 'test' => true } } }
    let(:task) { Qyu::Task.create(queue_name: queue_name, attributes: attributes) }
    # like in the case of double delivery

    context 'when task is locked' do
      it 'unlocks the task' do
        task.lock!
        expect { task.unlock! }.to change { task.locked? }.from(true).to(false)
      end
    end

    context 'when the task is not locked' do
      it 'raises an exception' do
        expect { task.unlock! }.to raise_error Qyu::Errors::LockNotAcquired
      end
    end
  end

  describe '#select_tasks_by_job_id' do
    let(:attributes) do
      {
        'payload' => {
          'name' => 'my_task', 'job_id' => 23_423, 'test' => true
        }
      }
    end
    let!(:task1) { Qyu::Task.create(queue_name: 'my_queue1', attributes: attributes) }
    let!(:task2) { Qyu::Task.create(queue_name: 'my_queue2', attributes: attributes) }

    it 'should return tasks of particular job' do
      tasks = Qyu::Task.select(job_id: task1.job_id)
      expect(tasks.map(&:id)).to match_array([task1.id, task2.id])
    end
  end
end

RSpec.describe Qyu::Task do
  describe 'InMemoryAdapter' do
    let(:store_config) { { type: :memory, lease_period: 60 } }
    include_examples 'task'
  end
end
