# Qyu 九

[![Gem Version](https://img.shields.io/gem/v/qyu.svg)](https://rubygems.org/gems/qyu)
[![Build Status](https://travis-ci.org/FindHotel/qyu.svg)](https://travis-ci.org/FindHotel/qyu)
[![Maintainability](https://api.codeclimate.com/v1/badges/88b8e0a8621d1da5c237/maintainability)](https://codeclimate.com/github/QyuTeam/qyu/maintainability)
[![Press](https://img.shields.io/badge/RubyWeekly-Blog%20Post-green.svg)](https://rubyweekly.com/link/44495/web)

## Requirements:
* Ruby 2.4.0 or newer

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'qyu'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install qyu

## Configuration
To start using Qyu; you need a queue configuration and a state store configuration. Here's an example:
```ruby
Qyu.configure(
  queue: {
    type: :memory
  },
  store: {
    type: :memory,
    lease_period: 60
  },
  # optional Defaults to STDOUT
  logger: Logger.new(STDOUT)
)
```

## Usage
[1] Connect all instances to the same state store and message queue  
[2] Create a workflow  
[3] Initialize a worker as follows  

```ruby
w = Qyu::Worker.new do
  # callbacks
  callback :execute, :before do
    Qyu.logger.info 'Waiting for task..'
  end

  callback :execute, :after do
    Qyu.logger.info 'Done'
  end

  # payload validation
  validates :times, presence: true, type: :integer

  # failure queue
  failure_queue false
end

w.work('queue-name') do |task|
  # to get the payload passed to the task
  task.payload
  # = { 'param_1' => true, 'param_2': [10, 11, 12], 'param_3' => 2 }

  # get the job
  task.job

  # to manually start a task
  task.job.create_task(task, 'next-task-name', payload)
rescue StandardError => ex
  # If you rescue the error for debugging or reporting purposes, you have to raise it at the end
  #
  # do something
  #
  raise ex
end
```

[4] Start worker  
[5] Start creating Jobs using the previously created workflow

## Plugins
The memory queue and store is just for testing purposes. For production; use one of the following:

#### Stores
*ActiveRecord:* https://github.com/FindHotel/qyu-store-activerecord    
*Redis:* https://github.com/FindHotel/qyu-store-redis

#### Queues
*Amazon SQS:* https://github.com/FindHotel/qyu-queue-sqs    
*Redis:* https://github.com/FindHotel/qyu-queue-redis

## Glossary

#### Workflow
The workflow specifies the entry points (`starts`), the tasks, their order, eventual dependencies between them, and synchronisation conditions.

#### Job
A job is essentially a collection of tasks and an initial JSON payload.

#### Task
A task is one unit of work. It is an instance of an entry from a workflow. You can think of it as the workflow's entries define the classes, while a task is a materialised instance of it, saved in the state store and enqueued on the message queue.

In the state store a task has:
* `id`
* `name` - it appears as the key in the workflow's `tasks`
* `queue_name` - the queue where the task was enqueued on creation
* `payload` - the entry/input parameters for the particular task
* `parent_task_id` - the ID of the task which created/enqueued the current task

When a task is created (saved & enqueued) then its `id` is put in a JSON message `{  task_id: task.id}` and enqueued on the specified task's message queue.
When a worker picks up the message from the queue, decodes the task id, and retrieves it from the state store.

#### Worker
A worker is sitting on a queue, waiting for something.

#### Sync Worker
A worker waiting for other workers to finish

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/QyuTeam/qyu.
