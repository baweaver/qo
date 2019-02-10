module Qo
  module Branches
    class FailureBranch < Branch
      def initialize(deconstruct: false)
        super(
          name: 'failure',
          deconstruct: deconstruct,
          precondition: -> v { v.first == :err },
          extractor: -> v { v.last },
          required: true,
        )
      end
    end
  end
end
