# frozen_string_literal: true

require 'sinatra'
require 'qyu/ui/helpers/pagination'

module Qyu #:nodoc: all
  class UI < Sinatra::Base
    set :port, ENV['PORT'] || 3000
    set :host, ENV['HOST'] || '0.0.0.0'

    set :views, "#{__dir__}/ui/views"
    set :public_folder, "#{__dir__}/ui/public"

    include Qyu::Helpers::Pagination

    get '/' do
      redirect to('/jobs')
    end

    get '/jobs' do
      page = params[:page].to_i > 0 ? params[:page].to_i : 1
      limit = 10
      offset = (page - 1) * limit

      jobs = PaginatableArray.new(
        Qyu::Job.select(limit: limit, offset: offset, order: :desc),
        limit: limit, offset: offset, total_count: Qyu::Job.count,
        page: page
      )

      erb :jobs, layout: true, locals: { jobs: jobs }
    end

    get '/jobs/:id' do
      job = Qyu::Job.find(params[:id])
      tasks_records = Qyu::Task.select(job_id: job.id)
      total_count = tasks_records.count
      task_statuses = job.task_status_counts
      tasks = tasks_records.group_by(&:parent_task_id)
      erb :show_job,
        layout: true,
        locals: {
          job: job,
          tasks: tasks,
          total_count: total_count,
          task_statuses: task_statuses
        }
    end

    private

    def raw_html(value)
      String.respond_to?(:html_safe) ? value.html_safe : value
    end
  end
end
