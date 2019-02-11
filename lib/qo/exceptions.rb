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
  end
end
