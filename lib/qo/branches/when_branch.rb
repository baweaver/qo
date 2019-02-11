module Qo
  module Branches
    class WhenBranch < Branch
      def initialize(destructure: false)
        super(name: 'when', destructure: destructure, default: false)
      end
    end
  end
end
