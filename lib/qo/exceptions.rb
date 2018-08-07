module Qo
  # Defines common exception classes for use throughout the library
  #
  # @author baweaver
  # @since 0.2.0
  #
  module Exceptions
    # If no matchers in either Array or Hash style are provided.
    #
    # @author baweaver
    # @since 0.2.0
    #
    class NoMatchersProvided < ArgumentError
      def to_s
        "No Qo matchers were provided!"
      end
    end

    # If both Array and Hash style matchers are provided.
    #
    # @author baweaver
    # @since 0.2.0
    #
    class MultipleMatchersProvided < ArgumentError
      def to_s
        "Cannot provide both array and keyword matchers!"
      end
    end

    # In the case of a Pattern Match, we should only have one "else" clause
    #
    # @author baweaver
    # @since 0.3.0
    #
    class MultipleElseClauses < ArgumentError
      def to_s
        "Cannot have more than one `else` clause in a Pattern Match."
      end
    end
  end
end
