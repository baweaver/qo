require 'qo/evil/matcher'
require 'qo/evil/guard_block_matcher'
require 'qo/evil/pattern_match'

module Qo
  module Evil
    class << self
      def and(*as, **ks)
        Qo::Evil::Matcher.new('and', as, ks)
      end

      def or(*as, **ks)
        Qo::Evil::Matcher.new('or', as, ks)
      end

      def not(*as, **ks)
        Qo::Evil::Matcher.new('not', as, ks)
      end

      def matcher(*array_matchers, **keyword_matchers, &fn)
        Qo::Evil::GuardBlockMatcher.new(array_matchers, keyword_matchers, fn)
      end

      # Might be a tinge fond of shorthand
      alias_method :m, :matcher

      def match(*args)
        if args.first.is_a?(Qo::Evil::GuardBlockMatcher)
          Qo::Evil::PatternMatch.new(args)
        else
          match_target, *qo_matchers = args
          Qo::Evil::PatternMatch.new(qo_matchers).call(match_target)
        end
      end
    end
  end
end
