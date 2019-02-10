module Qo
  module Branches
    class WhenBranch < Branch
      def initialize(deconstruct: false)
        super(name: 'when', deconstruct: deconstruct, default: false, required: false)
      end
    end
  end
end
