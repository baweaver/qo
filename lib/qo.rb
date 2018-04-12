require "qo/version"
require 'qo/matcher'
require 'qo/guard_block_matcher'

module Qo
  WILDCARD_MATCH = :*

  class << self
    def m(*array_matchers, **keyword_matchers, &fn)
      Qo::GuardBlockMatcher.new(*array_matchers, **keyword_matchers, &fn)
    end

    def match(data, *qo_matchers)
      all_are_guards = qo_matchers.all? { |q| q.is_a?(Qo::GuardBlockMatcher)}
      raise 'Must patch Qo GuardBlockMatchers!' unless all_are_guards

      qo_matchers.reduce(nil) { |_, matcher|
        did_match, match_result = matcher.call(data)
        break match_result if did_match
      }
    end

    def match_fn(*qo_matchers)
      -> data { match(data, *qo_matchers) }
    end

    def and(*array_matchers, **keyword_matchers)
      Qo::Matcher.new('and', *array_matchers, **keyword_matchers)
    end

    def [](*array_matchers, **keyword_matchers)
      Qo::Matcher.new('and', *array_matchers, **keyword_matchers)
    end

    def or(*array_matchers, **keyword_matchers)
      Qo::Matcher.new('or', *array_matchers, **keyword_matchers)
    end

    def not(*array_matchers, **keyword_matchers)
      Qo::Matcher.new('not', *array_matchers, **keyword_matchers)
    end
  end
end
