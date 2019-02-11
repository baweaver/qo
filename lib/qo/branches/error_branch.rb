module Qo
  module Branches
    # A tuple branch that will be triggered when the first value is
    # `:err`.
    #
    # ```ruby
    # ResultPatternMatch.new { |m|
    #   m.error { |v| "This is the error: #{v}" }
    # }.call([:err, 'OH NO!'])
    # # => "This is the error: OH NO!"
    # ```
    #
    # @author baweaver
    # @since 1.0.0
    class ErrorBranch < Branch
      def initialize(destructure: false)
        super(
          name: 'error',
          destructure: destructure,
          precondition: -> v { v.first == :err },
          extractor: :last,
        )
      end
    end
  end
end
