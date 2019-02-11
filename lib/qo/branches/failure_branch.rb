module Qo
  module Branches
    class FailureBranch < Branch
      def initialize(destructure: false)
        super(
          name: 'failure',
          destructure: destructure,
          precondition: -> v { v.first == :err },
          extractor: :last,
        )
      end
    end
  end
end
