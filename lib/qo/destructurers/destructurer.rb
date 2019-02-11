module Qo
  module Destructurers
    class Destructurer
      def initialize(should_destructure:, &function)
        @should_destructure = should_destructure
        @function           = function || IDENTITY
        @argument_names     = argument_names
      end

      def call(target)
        destructured_arguments = destructure? ? destructure_values(target) : target

        @function.call(destructured_arguments)
      end

      def destructure?
        @should_destructure
      end

      def destructure_values(target)
        target.is_a?(::Hash) ?
          argument_names.map { |n| target[n] } :
          argument_names.map { |n| target.respond_to?(n) && target.public_send(n) }
      end

      def argument_names
        @argument_names ||= @function.parameters.map(&:last)
      end
    end
  end
end
