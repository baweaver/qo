module Qo
  module PatternMatchers
    class ResultPatternMatch < PatternMatch
      DEFAULT_BRANCHES = [
        Qo::Branches::SuccessBranch.new,
        Qo::Branches::FailureBranch.new,
      ]

      def initialize(deconstruct: false)
        super(branches: DEFAULT_BRANCHES)
      end
    end
  end
end
