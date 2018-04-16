module Qo
  module Matchers
    class CaseClassMatcher < BaseMatcher
      # Identity function that returns its argument directly
      IDENTITY  = -> v { v }

      # Definition of a non-match
      NON_MATCH = [false, false]

      def initialize(*array_matchers, **keyword_matchers, &fn)
        @fn = fn || IDENTITY

        super('and', *array_matchers, **keyword_matchers)
      end

      def to_proc(&fn)
        @fn = fn if fn

        Proc.new { |target|
          did_match = super[target]
          next NON_MATCH unless did_match

          matched_keys = target.slice(*@keyword_matchers.keys)
          extract_data = target.select { |k, v| matched_keys.include?(k) }.values

          [true, @fn.call(*extract_data)]
        }
      end
    end
  end
end
