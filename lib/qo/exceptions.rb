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
    # Error for not all possible cases being handled. This is optimistic as currently
    # it will only catch when an actual failure to handle a case is present. This
    # should be patched in later versions
    #
    # @author baweaver
    # @since 0.99.1
    class ExhaustiveMatchNotMet < StandardError
      MESSAGE = 'Exhaustive match required - pattern does not satisfy all possible conditions'

      def initialize
        super(MESSAGE)
      end
    end
  end
end
