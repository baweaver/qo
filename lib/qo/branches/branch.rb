module Qo
  module Branches
    class Branch
      UNMATCHED = [false, nil]

      attr_accessor :destructure

      attr_reader :name

      def initialize(name:, precondition: Any, extractor: IDENTITY, destructure: false, default: false)
        @name         = name
        @precondition = precondition.is_a?(Symbol) ? precondition.to_proc : precondition
        @extractor    = extractor.is_a?(Symbol)    ? extractor.to_proc    : extractor
        @destructure  = destructure
        @default      = default
      end

      def self.create(name:, precondition: Any, extractor: IDENTITY, destructure: false, default: false)
        attributes = {
          name:         name,
          precondition: precondition,
          extractor:    extractor,
          destructure:  destructure,
          default:      default
        }

        Class.new(Qo::Branches::Branch) do
          define_method(:initialize) { super(**attributes) }
        end
      end

      def default?
        @default
      end

      def create_matcher(conditions, should_destructure: false, &function)
        function ||= IDENTITY

        destructurer = Destructurers::Destructurer.new(
          should_destructure: should_destructure, &function
        )

        Proc.new { |value|
          extracted_value = @extractor.call(value)

          next [true, destructurer.call(extracted_value)] if @default

          if @precondition === value && conditions === extracted_value
            [true, destructurer.call(extracted_value)]
          else
            UNMATCHED
          end
        }
      end
    end
  end
end
