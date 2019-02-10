module Qo
  module Branches
    class MonadicWhereBranch < Branch
      def initialize(deconstruct: false, extractor: :value)
        super(
          name: 'where',
          deconstruct: deconstruct,
          extractor: extractor,
          default: false,
          required: false
        )
      end
    end
  end
end
