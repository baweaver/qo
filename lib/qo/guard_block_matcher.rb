module Qo
  class GuardBlockMatcher < Matcher
    IDENTITY = -> v { v }

    def initialize(*array_matchers, **keyword_matchers, &fn)
      @fn = fn || IDENTITY

      super('and', *array_matchers, **keyword_matchers)
    end

    def to_proc
      -> match_target {
        return [false, false] unless super[match_target]

        [true, @fn.call(match_target)]
      }
    end
  end
end
