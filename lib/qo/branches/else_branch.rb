module Qo
  module Branches
    class ElseBranch < Branch
      def initialize(deconstruct: false)
        super(name: 'else', deconstruct: deconstruct, default: true, required: false)
      end
    end
  end
end
