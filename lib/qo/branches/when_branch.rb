module Qo
  module Branch
    class WhenBranch
      def initialize(matcher)

      end

      def register(&callback)
        @callback = callback
      end
    end
  end
end
