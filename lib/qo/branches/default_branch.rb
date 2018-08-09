module Qo
  module Branch
    class WhenBranch
      def initialize(matcher)
        @matcher = matcher
      end

      def register(&callback)
        @callback = callback
      end
    end
  end
end
