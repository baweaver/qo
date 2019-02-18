module Qo
  module PatternMatchers
    # Unlike the normal pattern matcher, this one works on tuple arrays containing
    # a status and a result like `[:ok, result]` and `[:err, message]`.
    #
    # Note that each of these can still take conditionals much like a `where`
    # branch for more fine grained control over what we're looking for.
    #
    # @example
    #   ```ruby
    #   matcher = Qo.result_match { |m|
    #     m.success(String) { |v| "Hello #{v}"}
    #     m.success         { |v| v + 10 }
    #     m.failure         { |v| "Error: #{v}" }
    #   }
    #
    #   matcher.call([:ok, 'there'])
    #   # => "Hello there"
    #
    #   matcher.call([:ok, 4])
    #   # => 14
    #
    #   matcher.call([:err, 'OH NO'])
    #   # => "Error: OH NO"
    #   ```
    #
    # @author baweaver
    # @since 1.0.0
    class ResultPatternMatch < PatternMatch
      register_branch Qo::Branches::SuccessBranch.new
      register_branch Qo::Branches::FailureBranch.new

      # Creates a new result matcher
      #
      # @param destructure: false [Boolean]
      #   Whether or not to destructure the value before yielding to
      #   the first matched block
      #
      # @param exhaustive: false [Boolean]
      #   If no matches are found, this will raise a
      #   `Qo::ExhaustiveMatchNotMet` error.
      #
      # @return [Qo::PatternMatch::ResultPatternMatch]
      def initialize(destructure: false, exhaustive: false)
        super(destructure: destructure, exhaustive: exhaustive)
      end
    end
  end
end
