module Qo
  module Matchers
    # A GuardBlockMatcher is like a regular matcher, except in that if it
    # "matches" it will provide its match target to its associated block.
    #
    # It returns tuples of (status, result) in order to prevent masking of
    # legitimate falsy or nil values returned.
    #
    # Guard Block Matchers are best used with a PatternMatch, and chances are
    # you're going to want to read that documentation first.
    #
    # @example
    #     Qo::Matchers::GuardBlockMatcher
    #
    #     guard_matcher = Qo::Matchers::GuardBlockMatcher.new(Integer) { |v| v * 2 }
    #     guard_matcher.call(1)  # => [true, 2]
    #     guard_matcher.call(:x) # => [false, false]
    #
    # @see Qo::Matchers::PatternMatch
    #   Pattern Match using GuardBlockMatchers
    #
    # @author baweaver
    # @since 0.1.5
    #
    class GuardBlockMatcher < BaseMatcher
      # Definition of a non-match
      NON_MATCH = [false, false]

      def initialize(array_matchers, keyword_matchers, &fn)
        @fn = fn || Qo::IDENTITY

        super('and', array_matchers, keyword_matchers)
      end

      # Overrides the base matcher's #to_proc to wrap the value in a status
      # and potentially call through to the associated block if a base
      # matcher would have passed
      #
      # @see Qo::Matchers::GuardBlockMatcher#call
      #
      # @return [Proc[Any]]
      #   Function awaiting target value
      def to_proc
        Proc.new { |target| self.call(target) }
      end


      # Overrides the call method to wrap values in a return tuple to represent
      # a positive match to guard against valid falsy returns
      #
      # @param target [Any]
      #   Target value to match against
      #
      # @return [Array[false, false]]
      #   The guard block did not match
      #
      # @return [Array[true, Any]]
      #   The guard block matched, and the provided function called through
      #   providing a return value.
      def call(target)
        super(target) ? [true, @fn.call(target)] : NON_MATCH
      end
    end
  end
end
