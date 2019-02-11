module Qo
  module Branches
    # Based on the `else` branch, except deals with monadic values by attempting
    # to extract the `value` before yielding to the given function on a match:
    #
    # ```ruby
    # Matcher.new.call(Some[1]) { |m|
    #   m.else { |v| v + 2 }
    # }
    # # => 3
    # ```
    #
    # @author baweaver
    # @since 1.0.0
    class MonadicElseBranch < Branch
      def initialize(destructure: false, extractor: :value)
        super(
          name: 'else',
          destructure: destructure,
          extractor: extractor,
          default: true,
        )
      end
    end
  end
end
