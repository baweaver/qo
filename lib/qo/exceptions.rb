module Qo
  # Defines common exception classes for use throughout the library
  #
  # Currently there aren't any exceptions being used, but keeping this
  # around for later use.
  #
  # @author baweaver
  # @since 0.2.0
  #
  module Exceptions
    # Common ancestor for all exceptions used in Qo
    Error = Class.new(StandardError)

    # Common ancestor for all matching errors
    MatchError = Class.new(Error)

    # Error for not all possible cases being handled. This is optimistic as currently
    # it will only catch when an actual failure to handle a case is present. This
    # should be patched in later versions
    #
    # @author baweaver
    # @since 0.99.1
    class ExhaustiveMatchNotMet < MatchError
      MESSAGE = 'Exhaustive match required: pattern does not satisfy all possible conditions'

      def initialize
        super(MESSAGE)
      end
    end

    # Not all branches were definied in an exhaustive matcher
    #
    # @author baweaver
    # @since 0.99.1
    class ExhaustiveMatchMissingBranches < MatchError
      def initialize(expected_branches:, given_branches:)
        super <<~MESSAGE
          Exhaustive match required: pattern does not specify all branches.
            Expected Branches: #{expected_branches.to_a.join(', ')}
            Given Branches:    #{given_branches.to_a.join(', ')}
        MESSAGE
      end
    end
  end
end
