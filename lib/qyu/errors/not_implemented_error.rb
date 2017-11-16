# frozen_string_literal: true

module Qyu
  module Errors
    # Qyu::Errors::NotImplementedError
    class NotImplementedError < Base
      def initialize
        super('Abstract method. Should have been overwritten.')
      end
    end
  end
end
