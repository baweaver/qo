module Qo
  module Destructurers
    # Classic destructuring. This gives great value to the names of a function's
    # arguments, transforming the way blocks are normally yielded to. Take for
    # example this function:
    #
    # ```ruby
    # Proc.new { |name, age| ... }
    # ```
    #
    # The names of the arguments are `name` and `age`. Destructuring involves
    # using these names to extract the values of an object before the function
    # is called:
    #
    # 1. Get the names of the arguments
    # 2. Map over those names to extract values from an object by sending them
    #    as method calls
    # 3. Call the function with the newly extracted values
    #
    # It's highly suggested to read through the "Destructuring in Ruby" article
    # here:
    #
    # @see https://medium.com/rubyinside/destructuring-in-ruby-9e9bd2be0360
    #
    # @author baweaver
    # @since 1.0.0
    class Destructurer
      # Creates a destructurer
      #
      # @param destructure: [Boolean]
      #   Whether or not to destructure an object before calling a function
      #
      # @param &function [Proc]
      #   Associated function to be called
      #
      # @return [Qo::Destructurers::Destructurer]
      def initialize(destructure:, &function)
        @destructure    = destructure
        @function       = function || IDENTITY
        @argument_names = argument_names
      end

      # Calls the destructurer to extract values from a target and call the
      # function with those extracted values.
      #
      # @param target [Any]
      #   Target to extract values from
      #
      # @return [Any]
      #   Return of the given function
      def call(target)
        destructured_arguments = destructure? ? destructure_values(target) : target

        @function.call(destructured_arguments)
      end

      # Whether or not this method will destructure a passed object
      #
      # @return [Boolean]
      def destructure?
        @destructure
      end

      # Destructures values from a target object
      #
      # @param target [Any]
      #   Object to extract values from
      #
      # @return [Array[Any]]
      #   Extracted values
      def destructure_values(target)
        target.is_a?(::Hash) ?
          argument_names.map { |n| target[n] } :
          argument_names.map { |n| target.respond_to?(n) && target.public_send(n) }
      end

      # Names of the function's arguments
      #
      # @return [Array[Symbol]]
      def argument_names
        @argument_names ||= @function.parameters.map(&:last)
      end
    end
  end
end
