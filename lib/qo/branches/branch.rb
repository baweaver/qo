module Qo
  module Branches
    class Branch
      UNMATCHED = [false, nil]

      attr_accessor :deconstruct

      attr_reader :name

      def initialize(name:, precondition: Any, extractor: IDENTITY, deconstruct: false, default: false, required: false)
        @name         = name
        @precondition = precondition.is_a?(Symbol) ? precondition.to_proc : precondition
        @extractor    = extractor.is_a?(Symbol)    ? extractor.to_proc    : extractor
        @deconstruct  = deconstruct
        @default      = default
        @required     = required
      end

      def required?
        @required
      end

      def default?
        @default
      end

      def create_matcher(conditions, &function)
        Proc.new { |value|
          extracted_value  = @extractor.call(value)

          next [true, deconstruct(extracted_value, &function)] if @default

          if @precondition === value && conditions === extracted_value
            [true, deconstruct(extracted_value, &function)]
          else
            UNMATCHED
          end
        }
      end

      def deconstruct(value, &function)
        return function.call(value) unless @deconstruct

        extracted_names  = function.parameters.map(&:last)
        extracted_values = value.is_a?(Hash) ?
          extracted_names.map { |n| value[n] } :
          extracted_names.map { |n| value.public_send(n) }

        function.call(*extracted_values)
      end
    end
  end
end
