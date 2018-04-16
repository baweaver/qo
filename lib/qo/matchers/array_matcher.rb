module Qo
  module Matchers
    # An Array Matcher is a matcher that uses only varargs to define a sequence
    # of matches to perform against either an object or another Array.
    #
    # In the case of an Array matching against an Array it will compare via index.
    #
    # In the case of an Array matching against an Object, it will match each provided
    # matcher against the object.
    #
    # All variants present in the BaseMatcher are present here, including 'and',
    # 'not', and 'or'.
    #
    # @author [baweaver]
    #
    class ArrayMatcher < BaseMatcher
      # Used to match against a matcher made from an Array, like:
      #
      #     Qo['Foo', 'Bar']
      #
      # @param matchers [Array[respond_to?(===)]] indexed tuple to match the target object against
      #
      # @return [Proc[Any]]
      #     Array  -> Bool # Tuple match against targets index
      #     Object -> Bool # Boolean public send
      def to_proc
        Proc.new { |target| self.call(target) }
      end

      # Invocation for the match sequence. Will determine the target and applicable
      # matchers to run against it.
      #
      # @param target [Any]
      #
      # @return [Boolean] Match status
      def call(target)
        return true if @array_matchers == target

        if target.is_a?(::Array)
          match_with(@array_matchers.each_with_index) { |matcher, i|
            match_value?(target[i], matcher)
          }
        else
          match_with(@array_matchers) { |matcher|
            match_value?(target, matcher)
          }
        end
      end

      # Defines what it means for a value to match a matcher
      #
      # @param target  [Any] Target to match against
      # @param matcher [Any] Any matcher to run against, most frequently responds to ===
      #
      # @return [Boolean] Match status
      private def match_value?(target, matcher)
        wildcard_match?(matcher) ||
        case_match?(target, matcher) ||
        method_matches?(target, matcher)
      end
    end
  end
end
