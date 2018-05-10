module Qo
  module Evil
    class GuardBlockMatcher < Matcher
      attr_reader :fn

      IDENTITY  = -> v { v }

      # Definition of a non-match
      NON_MATCH = [false, false]

      def initialize(array_matchers, keyword_matchers, fn)
        @fn = fn || IDENTITY
        super('and', array_matchers, keyword_matchers)
      end

      def pre_render(target)
        self.call(target)
        @query
      end

      def render(target)
        self.call(target) ? [true, @fn.call(target)] : NON_MATCH
      end
    end
  end
end
