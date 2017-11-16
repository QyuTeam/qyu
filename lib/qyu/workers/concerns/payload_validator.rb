# frozen_string_literal: true

module Qyu
  module Workers
    module Concerns
      # Qyu::Concerns::PayloadValidator
      module PayloadValidator
        # Adds ability to workers to perform validations on
        # params for the task to be processed
        #
        # Usage:
        #
        # Qyu::Worker.new do
        #   validates :user_id,    presence: true, type: :integer, unless: :no_user
        #   validates :name,       presence: true, type: :string
        #   validates :account_id, absence: true,  if: :customer_id
        #   validates :account_id, presence: true, unless: :customer_id
        # end
        #

        def validates(parameter, opts = {})
          @_validations ||= {}
          @_validations[parameter.to_s] = Qyu::Utils.stringify_hash_keys(opts)
        end

        def validate_payload!(model)
          return unless @_validations
          payload = Qyu::Utils.stringify_hash_keys(model.payload || {})
          validation_errors = {}
          @_validations.each do |attribute, opts|
            # example: attribute :name
            # example opts { presence: true, type: integer }
            next unless if_validation(payload, opts['if'])
            next unless unless_validation(payload, opts['unless'])
            opts.map do |option, value|
              error = run_validation(option, payload[attribute.to_s], value)
              # next if error is nil
              next unless error
              validation_errors["#{attribute}.#{option}"] = error
            end
          end

          if validation_errors.size.positive?
            fail Qyu::Errors::PayloadValidationError, validation_errors
          end
          nil
        end

        private

        def run_validation(option, param, value)
          # Skip if and unless conditionals (return nil)
          return if option.eql?('if')
          return if option.eql?('unless')
          # supported options are presence, absence and type
          __send__(option, param, value)
        rescue NoMethodError
          raise Qyu::Errors::UnknownValidationOption, option
        end

        def presence(param, value)
          return unless value
          return unless param.nil?
          { expected: 'present' }
        end

        def absence(param, value)
          return unless value
          return if param.nil?
          { expected: 'absent' }
        end

        def type(param, data_type)
          __send__("#{data_type}_type_validator", param)
        end

        # DataType validators
        def integer_type_validator(param)
          type_validator('integer', [Integer], param.class)
        end

        def string_type_validator(param)
          type_validator('string', [String, Symbol], param.class)
        end

        def number_type_validator(param)
          type_validator('number', [Integer, Float], param.class)
        end

        def boolean_type_validator(param)
          type_validator('boolean', [TrueClass, FalseClass], param.class)
        end

        def hash_type_validator(param)
          type_validator('hash', [Hash], param.class)
        end

        def array_type_validator(param)
          type_validator('array', [Array], param.class)
        end

        def type_validator(type_name, data_types, param_class)
          return if data_types.include?(param_class)
          { expected: type_name, got: param_class.name.downcase }
        end

        # Conditonal validation
        def if_validation(payload, key)
          # TODO: support block passing "return yield if block_given?"
          return true if key.nil?
          return true if payload[key.to_s]
          false
        end

        def unless_validation(payload, key)
          # TODO: support block passing "return yield if block_given?"
          return true if key.nil?
          return true unless payload[key.to_s]
          false
        end
      end
    end
  end
end
