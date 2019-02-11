module Qo
  module Branches
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
