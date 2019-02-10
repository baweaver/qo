module Qo
  module Branches
    class SuccessBranch < Branch
      def initialize(deconstruct: false)
        super(
          name: 'success',
          deconstruct: deconstruct,
          precondition: -> v { v.first == :ok },
          extractor: -> v { v.last },
          required: true,
        )
      end
    end
  end
end
