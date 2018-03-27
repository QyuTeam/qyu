# frozen_string_literal: true

module Qyu
  module Workers
    module Concerns
      # Qyu::Workers::Concerns::Split
      #
      # Adds ability to split workers to specify slice size and splittable variable name
      #
      # Qyu::SplitWorker.new do
      #   slice_size 25
      #   payload_key 'array'
      # end
      #
      module Split

        @slice_size = 25

        # Configures slice size
        #
        #   slice_size 25
        #
        # @param slice_size [Integer]
        def slice_size(slsz)
          @slice_size = slsz
        end

        # Configures payload key with array to split
        #
        #   payload_key 25
        #
        # @param payload_key [String]
        def payload_key(var_name)
          @payload_key = var_name
        end

        private
        def validate_split_parameters!
          if @payload_key.nil?
            raise Qyu::Errors::MissingSplitParameters.new('payload_key')
          end

          if @slice_size.nil?
            raise Qyu::Errors::MissingSplitParameters.new('slice_size')
          end
        end
      end
    end
  end
end
