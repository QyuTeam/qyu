# frozen_string_literal: true

module Qyu
  module Errors
    # Qyu::Errors::JobNotFound
    class JobNotFound < Base
      attr_reader :original_error
      def initialize(id, original_error)
        super("Job not found with id=#{id}.")
        @original_error = original_error
      end
    end
  end
end
