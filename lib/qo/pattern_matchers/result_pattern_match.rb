module Qo
  module PatternMatchers
    class ResultPatternMatch < PatternMatch
      register_branch Qo::Branches::SuccessBranch.new
      register_branch Qo::Branches::FailureBranch.new

      def initialize(destructure: false)
        super(destructure: destructure)
      end
    end
  end
end
