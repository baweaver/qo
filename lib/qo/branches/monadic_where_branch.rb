module Qo
  module Branches
    # Based on the `where` branch, except deals with monadic values by attempting
    # to extract the `value` before yielding to the given function on a match:
    #
    # ```ruby
    # Matcher.new.call(Some[1]) { |m|
    #   m.where(Some) { |v| v + 2 }
    # }
    # # => 3
    # ```
    #
    # @author baweaver
    # @since 1.0.0
    class MonadicWhereBranch < Branch
      def initialize(destructure: false, extractor: :value)
        super(
          name: 'where',
          destructure: destructure,
          extractor: extractor,
          default: false,
        )
      end
    end
  end
end
