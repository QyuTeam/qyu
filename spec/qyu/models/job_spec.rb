# frozen_string_literal: true

RSpec.shared_examples 'job' do
  let(:payload) { { 'ids' => [1, 2, 3] } }
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

  let(:workflow) { Qyu::Workflow.create(name: 'sample-workflow', descriptor: descriptor) }

  describe '#create' do
    it 'persists the Job in the StateStore' do
      id = Qyu::Job.create(workflow: workflow, payload: payload).id
      expect(Qyu.store.find_job(id)['payload']).to eq payload
      expect(Qyu.store.find_job(id)['workflow']['descriptor']).to eq descriptor
    end
  end

  describe '#find' do
    let(:workflow) { Qyu::Workflow.create(name: 'sample-workflow', descriptor: descriptor) }
    let(:job) { Qyu::Job.create(workflow: workflow, payload: payload) }

    it 'finds the job' do
      j = Qyu::Job.find(job.id)
      expect(j.payload).to eq payload
      expect(j.descriptor).to eq descriptor
    end
  end

  describe '#select' do
    before do
      10.times { Qyu::Job.create(workflow: workflow, payload: payload) }
      @payload2 = { 'ids' => [7, 8, 9] }
      Qyu::Job.create(workflow: workflow, payload: @payload2)
    end

    it 'loads correct amount of jobs' do
      jobs = Qyu::Job.select(limit: 5, offset: 0)
      expect(jobs.count).to eq(5)
    end

    it 'loads jobs with correct offset' do
      jobs = Qyu::Job.select(limit: 10, offset: 10)
      expect(jobs.count).to eq(1)
      expect(jobs[0].payload).to eq(@payload2)
    end
  end

  describe '#count' do
    before do
      @count = rand(1..10)
      @count.times { Qyu::Job.create(workflow: workflow, payload: payload) }
    end

    it 'return number of jobs' do
      expect(Qyu::Job.count).to eq(@count)
    end
  end

  describe '#start' do
    # given
    let(:descriptor) do
      {
        'starts' => %w(variation_generation control_sample_generation),
        'tasks' => {
          'variation_generation' => {
            'queue' => 'something something'
          },
          'control_sample_generation' => {
            'queue' => 'something something'
          }
        }
      }
    end

    let(:workflow) { Qyu::Workflow.create(name: 'sample-workflow', descriptor: descriptor) }
    let(:job) { Qyu::Job.create(workflow: workflow, payload: payload) }

    # expect
    it 'calls #create_task on each of the starting tasks retrieved from the descriptor' do
      expect(job).to receive(:create_task).once.with(nil, 'variation_generation', payload)
      expect(job).to receive(:create_task).once.with(nil, 'control_sample_generation', payload)
    end

    # when
    after do
      job.start
    end
  end

  describe '#queue_name' do
    # given
    let(:task_name) { 'sample_task' }
    let(:queue) { 'sample_queue' }
    let(:descriptor) do
      {
        'starts' => [task_name],
        'tasks' => { task_name => { 'queue' => queue } }
      }
    end
    let(:workflow) { Qyu::Workflow.create(name: 'sample-workflow', descriptor: descriptor) }
    let(:job) { Qyu::Job.create(workflow: workflow, payload: payload) }

    # expect
    it 'gets queue name from descriptor' do
      expect(job.queue_name(task_name)).to eq(queue)
    end
  end

  describe '#next_task_names' do
    # given
    let(:task_name) { 'sample_task' }
    let(:starts) { %w(subsequent_unrelated_task_1 subsequent_unrelated_task_2) }
    let(:starts_with_params) do
      { 'subsequent_related_task_1' => { 'nr_tasks' => { 'count' => 'another_task_name' } } }
    end
    let(:descriptor) do
      {
        'starts' => [task_name],
        'tasks' =>
        {
          task_name => {
            'queue' => 'something',
            'starts' => starts,
            'starts_with_params' => starts_with_params
          },
          'subsequent_unrelated_task_1' => {
            'queue' => 'something1_1'
          },
          'subsequent_unrelated_task_2' => {
            'queue' => 'something1_2'
          },
          'subsequent_related_task_1' => {
            'queue' => 'something2_1',
            'waits_for' => {
              'subsequent_unrelated_task_1' => {
                'condition' => {
                  'param' => 'nr_tasks'
                }
              }
            }
          },
          'subsequent_related_task_2' => {
            'queue' => 'something2_2'
          }
        }
      }
    end

    let(:workflow) { Qyu::Workflow.create(name: 'sample-workflow', descriptor: descriptor) }
    let(:job) { Qyu::Job.create(workflow: workflow, payload: payload) }

    # expect
    it 'gets next task names' do
      expect(job.next_task_names(task_name)).to eq({
                                                     'without_params' => starts,
                                                     'with_params' => starts_with_params
                                                   })
    end
  end

  describe '#tasks_to_wait_for' do
    # given
    let(:task_name) { 'sample_task' }
    let(:task) do
      Qyu::Task.create(
        queue_name: 'sample_queue',
        attributes: {
          'name' => task_name, 'job_id' => job.id, 'parent_task_id' => nil, 'payload' => payload
      })
    end
    let(:waits_for) do
      {
        'waiting_task_1' => {
          'condition' => {
            'param' => 'nr_tasks'
          }
        },
        'waiting_task_2' => {
          'condition' => {
            'param' => 'nr_tasks'
          }
        }
      }
    end
    let(:descriptor) do
      {
        'starts' => [task_name],
        'tasks' => {
          task_name => {
            'queue' => 'something',
            'waits_for' => waits_for
          },
          'waiting_task_1' => {
            'queue' => 'something2'
          },
          'waiting_task_2' => {
            'queue' => 'something2'
          }
        }
      }
    end
    let(:workflow) { Qyu::Workflow.create(name: 'sample-workflow', descriptor: descriptor) }
    let(:job) { Qyu::Job.create(workflow: workflow, payload: payload) }

    # expect
    it 'gets tasks to wait for' do
      expect(job.tasks_to_wait_for(task)).to match_array(waits_for.keys)
    end
  end

  describe '#create_task' do
    # given
    let(:task_name) { 'sample_task' }
    let(:queue) { 'sample_queue' }
    let(:descriptor) do
      { 'starts' => [task_name], 'tasks' => { task_name => { 'queue' => queue } } }
    end

    let(:workflow) { Qyu::Workflow.create(name: 'sample-workflow', descriptor: descriptor) }
    let(:job) { Qyu::Job.create(workflow: workflow, payload: payload) }

    # expect
    it 'creates specified task' do
      expect(Qyu::Task).to receive(:create).with(queue_name: queue, attributes: {
                                                     'name' => task_name,
                                                     'job_id' => job.id,
                                                     'payload' => payload,
                                                     'parent_task_id' => nil
                                                   })
    end

    after do
      job.create_task(nil, task_name, payload)
    end
  end

  describe '#create_next_tasks' do
    context 'with shared payload' do
      # given
      let(:task_name) { 'parent_task' }
      let(:parent_task) do
        Qyu::Task.create(
          queue_name: 'sample_queue',
          attributes: { 'name' => task_name, 'job_id' => job.id, 'payload' => payload }
        )
      end
      let(:starts) { %w(subsequent_unrelated_task_1 subsequent_unrelated_task_2) }
      let(:descriptor) do
        {
          'starts' => [task_name],
          'tasks' => {
            task_name => {
              'queue' => 'something',
              'starts' => starts
            }
          }
        }
      end

      let(:workflow) { Qyu::Workflow.create(name: 'sample-workflow', descriptor: descriptor) }
      let(:job) { Qyu::Job.create(workflow: workflow, payload: payload) }

      # expect
      it 'creates subsequent tasks' do
        expect(job).to receive(:create_task).once.with(parent_task, 'subsequent_unrelated_task_1', payload)
        expect(job).to receive(:create_task).once.with(parent_task, 'subsequent_unrelated_task_2', payload)
      end

      after do
        job.create_next_tasks(parent_task, payload)
      end
    end

    context 'with mixed payload' do
      # given
      let(:payload) do
        {
          'shared_key_1' => 'shared_value',
          task_name => {
            "#{task_name}_key" => "#{task_name}_value"
          },
          child_task_1 => {
            "#{child_task_1}_key_1" => "#{child_task_1}_value",
            "#{child_task_1}_key_2" => "#{child_task_1}_value_blah",
            'should_be_overriden' => "should_be_overriden_#{child_task_1}value"
          },
          child_task_2 => {
            "#{child_task_2}_key_1" => "#{child_task_2}_value",
            "#{child_task_2}_key_2" => "#{child_task_2}_value_blah",
            'should_be_overriden' => "should_be_overriden_#{child_task_2}value"
          },
          'shared_key_2' => 'shared_value',
          'shared_hash_key' => {
            'some_option' => 'option_value'
          },
          'should_be_overriden' => 'should_be_overriden_value'
        }
      end
      let(:task_name) { 'parent_task' }
      let(:parent_task) do
        Qyu::Task.create(
          queue_name: 'sample_queue',
          attributes: { 'name' => task_name, 'job_id' => job.id, 'payload' => payload }
        )
      end
      let(:starts) { [child_task_1, child_task_2] }
      let(:child_task_1) { 'subsequent_unrelated_task_1' }
      let(:child_task_2) { 'subsequent_unrelated_task_2' }
      let(:descriptor) do
        {
          'starts' => [task_name],
          'tasks' => {
            task_name => {
              'queue' => 'something',
              'starts' => starts
            },
            child_task_1 => {
              'queue' => 'child_smth_1'
            },
            child_task_2 => {
              'queue' => 'child_smth_2'
            }
          }
        }
      end
      let(:workflow) { Qyu::Workflow.create(name: 'sample-workflow', descriptor: descriptor) }
      let(:job) { Qyu::Job.create(workflow: workflow, payload: payload) }
      let(:expected_child_1_payload) do
        {
          'shared_key_1' => 'shared_value',
          "#{child_task_1}_key_1" => "#{child_task_1}_value",
          "#{child_task_1}_key_2" => "#{child_task_1}_value_blah",
          'should_be_overriden' => "should_be_overriden_#{child_task_1}value",
          'shared_key_2' => 'shared_value',
          'shared_hash_key' => {
            'some_option' => 'option_value'
          }
        }
      end
      let(:expected_child_2_payload) do
        {
          'shared_key_1' => 'shared_value',
          "#{child_task_2}_key_1" => "#{child_task_2}_value",
          "#{child_task_2}_key_2" => "#{child_task_2}_value_blah",
          'should_be_overriden' => "should_be_overriden_#{child_task_2}value",
          'shared_key_2' => 'shared_value',
          'shared_hash_key' => {
            'some_option' => 'option_value'
          }
        }
      end

      # expect
      it 'creates subsequent tasks' do
        expect(Qyu::Task).to receive(:create).once.with(
          queue_name: descriptor['tasks'][child_task_1]['queue'],
          attributes: {
            'name' => child_task_1,
            'parent_task_id' => parent_task.id,
            'job_id' => job.id,
            'payload' => expected_child_1_payload
          }
        )
        expect(Qyu::Task).to receive(:create).once.with(
          queue_name: descriptor['tasks'][child_task_2]['queue'],
          attributes: {
            'name' => child_task_2,
            'parent_task_id' => parent_task.id,
            'job_id' => job.id,
            'payload' => expected_child_2_payload
          }
        )
      end

      after do
        job.create_next_tasks(parent_task, payload)
      end
    end

    context 'with per tasks payload' do
      # given
      let(:payload) do
        {
          task_name => {
            "#{task_name}_key" => "#{task_name}_value"
          },
          child_task_1 => {
            "#{child_task_1}_key_1" => "#{child_task_1}_value",
            "#{child_task_1}_key_2" => "#{child_task_1}_value_blah"
          },
          child_task_2 => {
            "#{child_task_2}_key_1" => "#{child_task_2}_value",
            "#{child_task_2}_key_2" => "#{child_task_2}_value_blah"
          }
        }
      end
      let(:task_name) { 'parent_task' }
      let(:parent_task) do
        Qyu::Task.create(
          queue_name: 'sample_queue',
          attributes: { 'name' => task_name, 'job_id' => job.id, 'payload' => payload }
        )
      end
      let(:starts) { [child_task_1, child_task_2] }
      let(:child_task_1) { 'subsequent_unrelated_task_1' }
      let(:child_task_2) { 'subsequent_unrelated_task_2' }
      let(:descriptor) do
        {
          'starts' => [task_name],
          'tasks' => {
            task_name => {
              'queue' => 'something',
              'starts' => starts
            },
            child_task_1 => {
              'queue' => 'child_smth_1'
            },
            child_task_2 => {
              'queue' => 'child_smth_2'
            }
          }
        }
      end
      let(:workflow) { Qyu::Workflow.create(name: 'sample-workflow', descriptor: descriptor) }
      let(:job) { Qyu::Job.create(workflow: workflow, payload: payload) }
      let(:expected_child_1_payload) do
        {
          "#{child_task_1}_key_1" => "#{child_task_1}_value",
          "#{child_task_1}_key_2" => "#{child_task_1}_value_blah"
        }
      end

      let(:expected_child_2_payload) do
        {
          "#{child_task_2}_key_1" => "#{child_task_2}_value",
          "#{child_task_2}_key_2" => "#{child_task_2}_value_blah"
        }
      end

      # expect
      it 'creates subsequent tasks' do
        expect(Qyu::Task).to receive(:create).once.with(
          queue_name: descriptor['tasks'][child_task_1]['queue'],
          attributes: {
            'name' => child_task_1,
            'parent_task_id' => parent_task.id,
            'job_id' => job.id,
            'payload' => expected_child_1_payload
          }
        )
        expect(Qyu::Task).to receive(:create).once.with(
          queue_name: descriptor['tasks'][child_task_2]['queue'],
          attributes: {
            'name' => child_task_2,
            'parent_task_id' => parent_task.id,
            'job_id' => job.id,
            'payload' => expected_child_2_payload
          }
        )
      end

      after do
        job.create_next_tasks(parent_task, payload)
      end
    end
  end

  describe '#find_task_ids_by_name' do
    let(:descriptor) do
      {
        'starts' => [
          'build:campaign'
        ],
        'tasks' => {
          'build:campaign' => {
            'queue' => 'build-campaign',
            'starts_manually' => ['build:entity:cache'],
            'starts_with_params' => {
              'build:language:collect' => {
                'nr_tasks' => {
                  'count' => 'build:entity:cache'
                }
              }
            }
          },
          'build:entity:cache' => {
            'queue' => 'build-entity-cache',
            'starts' => ['build:slice:input']
          },
          'build:slice:input' => {
            'queue' => 'build-slice-input',
            'starts_manually' => ['build:ads'],
            'starts_with_params' => {
              'build:collect' => {
                'nr_tasks' => {
                  'count' => 'build:ads'
                }
              }
            }
          },
          'build:ads' => {
            'queue' => 'build-ads'
          },
          'build:collect' => {
            'waits_for' => {
              'build:ads' => {
                'condition' => {
                  'param' => 'nr_tasks',
                  'function' => 'eq_completed'
                }
              }
            },
            'queue' => 'build-collect'
          },
          'build:language:collect' => {
            'waits_for' => {
              'build:collect' => {
                'condition' => {
                  'param' => 'nr_tasks',
                  'function' => 'eq_completed'
                }
              }
            },
            'queue' => 'build-language-collect'
          }
        }
      }
    end
    let(:workflow) { Qyu::Workflow.create(name: 'sample-workflow', descriptor: descriptor) }
    let!(:job) { Qyu::Job.create(workflow: workflow, payload: payload) }
    let!(:ancestor_task)  do
      Qyu::Task.create(
        queue_name: 'build-campaign',
        attributes: { 'job_id' => job.id, 'payload' => {}, 'parent_task_id' => nil, 'name' => 'build:campaign' })
    end
    let!(:cache_task_1)   do
      Qyu::Task.create(
        queue_name: 'build-entity-cache',
        attributes: { 'job_id' => job.id, 'payload' => { language_code: 'de' }, 'parent_task_id' => ancestor_task.id, 'name' => 'build:entity:cache' })
    end
    let!(:slice_task_1)   do
      Qyu::Task.create(
        queue_name: 'build-slice-input',
        attributes: { 'job_id' => job.id, 'payload' => { language_code: 'de' }, 'parent_task_id' => cache_task_1.id, 'name' => 'build:slice:input' })
    end
    let!(:parse_task_1_1) do
      Qyu::Task.create(
        queue_name: 'build-ads',
        attributes: { 'job_id' => job.id, 'payload' => { language_code: 'de', hid: 123 }, 'parent_task_id' => slice_task_1.id, 'name' => 'build:ads' })
    end
    let!(:parse_task_1_2) do
      Qyu::Task.create(
        queue_name: 'build-ads',
        attributes: { 'job_id' => job.id, 'payload' => { language_code: 'de', hid: 456 }, 'parent_task_id' => slice_task_1.id, 'name' => 'build:ads' })
    end
    let!(:collect_task_1) do
      Qyu::Task.create(
        queue_name: 'build-collect',
        attributes: { 'job_id' => job.id, 'payload' => { language_code: 'de' }, 'parent_task_id' => slice_task_1.id, 'name' => 'build:collect' })
    end
    let!(:cache_task_2)   do
      Qyu::Task.create(
        queue_name: 'build-entity-cache',
        attributes: { 'job_id' => job.id, 'payload' => { language_code: 'en' }, 'parent_task_id' => ancestor_task.id, 'name' => 'build:entity:cache' })
    end
    let!(:slice_task_2)   do
      Qyu::Task.create(
        queue_name: 'build-slice-input',
        attributes: { 'job_id' => job.id, 'payload' => { language_code: 'en' }, 'parent_task_id' => cache_task_2.id, 'name' => 'build:slice:input' })
    end
    let!(:parse_task_2_1) do
      Qyu::Task.create(
        queue_name: 'build-ads',
        attributes: { 'job_id' => job.id, 'payload' => { language_code: 'en', hid: 123 }, 'parent_task_id' => slice_task_2.id, 'name' => 'build:ads' })
    end
    let!(:parse_task_2_2) do
      Qyu::Task.create(
        queue_name: 'build-ads',
        attributes: { 'job_id' => job.id, 'payload' => { language_code: 'en', hid: 456 }, 'parent_task_id' => slice_task_2.id, 'name' => 'build:ads' })
    end
    let!(:collect_task_2) do
      Qyu::Task.create(
        queue_name: 'build-collect',
        attributes: { 'job_id' => job.id, 'payload' => { language_code: 'en' }, 'parent_task_id' => slice_task_2.id, 'name' => 'build:collect' })
    end
    let!(:collector_task) do
      Qyu::Task.create(
        queue_name: 'build-language-collect',
        attributes: { 'job_id' => job.id, 'payload' => {}, 'parent_task_id' => ancestor_task.id, 'name' => 'build:language:collect' })
    end

    it 'returns the ids of the tasks with the specified name' do
      expect(job.find_task_ids_by_name('build:ads')).to match_array([parse_task_1_1.id, parse_task_1_2.id, parse_task_2_1.id, parse_task_2_2.id])
    end
  end
  describe '#find_task_ids_by_name_and_ancestor_task_id' do
    let(:descriptor) do
      {
        'starts' => [
          'build:campaign'
        ],
        'tasks' => {
          'build:campaign' => {
            'queue' => 'build-campaign',
            'starts_manually' => ['build:entity:cache'],
            'starts_with_params' => {
              'build:language:collect' => {
                'nr_tasks' => {
                  'count' => 'build:entity:cache'
                }
              }
            }
          },
          'build:entity:cache' => {
            'queue' => 'build-entity-cache',
            'starts' => ['build:slice:input']
          },
          'build:slice:input' => {
            'queue' => 'build-slice-input',
            'starts_manually' => ['build:ads'],
            'starts_with_params' => {
              'build:collect' => {
                'nr_tasks' => {
                  'count' => 'build:ads'
                }
              }
            }
          },
          'build:ads' => {
            'queue' => 'build-ads'
          },
          'build:collect' => {
            'waits_for' => {
              'build:ads' => {
                'condition' => {
                  'param' => 'nr_tasks',
                  'function' => 'eq_completed'
                }
              }
            },
            'queue' => 'build-collect'
          },
          'build:language:collect' => {
            'waits_for' => {
              'build:collect' => {
                'condition' => {
                  'param' => 'nr_tasks',
                  'function' => 'eq_completed'
                }
              }
            },
            'queue' => 'build-language-collect'
          }
        }
      }
    end
    let(:workflow) { Qyu::Workflow.create(name: 'sample-workflow', descriptor: descriptor) }
    let!(:job) { Qyu::Job.create(workflow: workflow, payload: payload) }
    let!(:ancestor_task)  do
      Qyu::Task.create(
        queue_name: 'build-campaign',
        attributes: { 'job_id' => job.id, 'payload' => {}, 'parent_task_id' => nil, 'name' => 'build:campaign' })
    end
    let!(:cache_task_1)   do
      Qyu::Task.create(
        queue_name: 'build-entity-cache',
        attributes: { 'job_id' => job.id, 'payload' => { language_code: 'de' }, 'parent_task_id' => ancestor_task.id, 'name' => 'build:entity:cache' })
    end
    let!(:slice_task_1)   do
      Qyu::Task.create(
        queue_name: 'build-slice-input',
        attributes: { 'job_id' => job.id, 'payload' => { language_code: 'de' }, 'parent_task_id' => cache_task_1.id, 'name' => 'build:slice:input' })
    end
    let!(:parse_task_1_1) do
      Qyu::Task.create(
        queue_name: 'build-ads',
        attributes: { 'job_id' => job.id, 'payload' => { language_code: 'de', hid: 123 }, 'parent_task_id' => slice_task_1.id, 'name' => 'build:ads' })
    end
    let!(:parse_task_1_2) do
      Qyu::Task.create(
        queue_name: 'build-ads',
        attributes: { 'job_id' => job.id, 'payload' => { language_code: 'de', hid: 456 }, 'parent_task_id' => slice_task_1.id, 'name' => 'build:ads' })
    end
    let!(:collect_task_1) do
      Qyu::Task.create(
        queue_name: 'build-collect',
        attributes: { 'job_id' => job.id, 'payload' => { language_code: 'de' }, 'parent_task_id' => slice_task_1.id, 'name' => 'build:collect' })
    end
    let!(:cache_task_2)   do
      Qyu::Task.create(
        queue_name: 'build-entity-cache',
        attributes: { 'job_id' => job.id, 'payload' => { language_code: 'en' }, 'parent_task_id' => ancestor_task.id, 'name' => 'build:entity:cache' })
    end
    let!(:slice_task_2)   do
      Qyu::Task.create(
        queue_name: 'build-slice-input',
        attributes: { 'job_id' => job.id, 'payload' => { language_code: 'en' }, 'parent_task_id' => cache_task_2.id, 'name' => 'build:slice:input' })
    end
    let!(:parse_task_2_1) do
      Qyu::Task.create(
        queue_name: 'build-ads',
        attributes: { 'job_id' => job.id, 'payload' => { language_code: 'en', hid: 123 }, 'parent_task_id' => slice_task_2.id, 'name' => 'build:ads' })
    end
    let!(:parse_task_2_2) do
      Qyu::Task.create(
        queue_name: 'build-ads',
        attributes: { 'job_id' => job.id, 'payload' => { language_code: 'en', hid: 456 }, 'parent_task_id' => slice_task_2.id, 'name' => 'build:ads' })
    end
    let!(:collect_task_2) do
      Qyu::Task.create(
        queue_name: 'build-collect',
        attributes: { 'job_id' => job.id, 'payload' => { language_code: 'en' }, 'parent_task_id' => slice_task_2.id, 'name' => 'build:collect' })
    end
    let!(:collector_task) do
      Qyu::Task.create(
        queue_name: 'build-language-collect',
        attributes: { 'job_id' => job.id, 'payload' => {}, 'parent_task_id' => ancestor_task.id, 'name' => 'build:language:collect' })
    end

    it 'returns the ids of the tasks with the specified name and ancestor_task_id' do
      expect(job.find_task_ids_by_name_and_ancestor_task_id('build:ads', ancestor_task.id)).
        to match_array([parse_task_1_1.id, parse_task_1_2.id, parse_task_2_1.id, parse_task_2_2.id])
    end

    it 'returns the ids of the tasks with the specified name and ancestor_task_id' do
      expect(job.find_task_ids_by_name_and_ancestor_task_id('build:ads', slice_task_1.id)).
        to match_array([parse_task_1_1.id, parse_task_1_2.id])
    end
  end
end

RSpec.describe Qyu::Job do
  describe 'InMemoryAdapter' do
    let(:store_config) { { type: :memory, lease_period: 60 } }
    include_examples 'job'
  end
end
