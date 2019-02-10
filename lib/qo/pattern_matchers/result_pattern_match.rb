module Qo
  module PatternMatchers
    class ResultPatternMatch < PatternMatch
      register_branch Qo::Branches::SuccessBranch.new
      register_branch Qo::Branches::FailureBranch.new

      def initialize(deconstruct: false)
        super(deconstruct: deconstruct)
      end
    end
  end
end
