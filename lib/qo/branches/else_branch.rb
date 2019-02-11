module Qo
  module Branches
    class ElseBranch < Branch
      def initialize(destructure: false)
        super(name: 'else', destructure: destructure, default: true)
      end
    end
  end
end
