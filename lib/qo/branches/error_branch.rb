module Qo
  module Branches
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
