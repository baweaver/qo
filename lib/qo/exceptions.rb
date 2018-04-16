module Qo
  # Defines common exception classes for use throughout the library
  #
  # @author [baweaver]
  #
  module Exceptions
    # If no matchers in either Array or Hash style are provided.
    #
    # @author [lemur]
    #
    class NoMatchersProvided < ArgumentError
      def to_s
        "No Qo matchers were provided!"
      end
    end

    # If both Array and Hash style matchers are provided.
    #
    # @author [lemur]
    #
    class MultipleMatchersProvided < ArgumentError
      def to_s
        "Cannot provide both array and keyword matchers!"
      end
    end

    # In the case of a Pattern Match, we need to ensure all arguments are
    # GuardBlockMatchers.
    #
    # @author [lemur]
    #
    class NotAllGuardMatchersProvided < ArgumentError
      def to_s
        "All provided matchers must be of type Qo::Matchers::GuardBlockMatcher " +
        "defined with `Qo.matcher` or `Qo.m` instead of regular matchers."
      end
    end
  end
end
