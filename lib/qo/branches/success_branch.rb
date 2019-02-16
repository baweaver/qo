module Qo
  module Branches
    # A tuple branch that will be triggered when the first value is
    # `:ok`.
    #
    # ```ruby
    # ResultPatternMatch.new { |m|
    #   m.success { |v| v + 2 }
    # }.call([:ok, 1])
    # # => 3
    # ```
    #
    # @author baweaver
    # @since 1.0.0
    class SuccessBranch < Branch
      def initialize(destructure: false)
        super(
          name: 'success',
          destructure: destructure,
          precondition: -> v { v.first == :ok },
          extractor: :last,
        )
      end
    end
  end
end
