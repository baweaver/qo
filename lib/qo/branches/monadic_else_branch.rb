module Qo
  module Branches
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
