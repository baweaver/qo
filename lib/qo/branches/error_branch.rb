module Qo
  module Branches
    class ErrorBranch < Branch
      def initialize(deconstruct: false)
        super(
          name: 'error',
          deconstruct: deconstruct,
          precondition: -> v { v.first == :err },
          extractor: -> v { v.last },
          required: true,
        )
      end
    end
  end
end
