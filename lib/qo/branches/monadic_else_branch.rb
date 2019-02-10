module Qo
  module Branches
    class MonadicElseBranch < Branch
      def initialize(deconstruct: false, extractor: :value)
        super(
          name: 'else',
          deconstruct: deconstruct,
          extractor: extractor,
          default: true,
          required: false
        )
      end
    end
  end
end
