module Qo
  module Branches
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
