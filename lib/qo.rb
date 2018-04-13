require "qo/version"
require 'qo/matcher'
require 'qo/guard_block_matcher'

module Qo
  WILDCARD_MATCH = :*

  class << self

    # Creates a Guard Block matcher.
    #
    # A guard block matcher is used to guard a function from running unless
    # the left-hand matcher passes. Once called with a value, it will either
    # return `[false, false]` or `[true, Any]`.
    #
    # This wrapping is done to preserve intended false or nil responses,
    # and is unwrapped with match below.
    #
    # @param *array_matchers    [Array] varargs matchers
    # @param **keyword_matchers [Hash]  kwargs matchers
    # @param &fn                [Proc]  Guarded function
    #
    # @return [Proc[Any]]
    #     Any -> Proc[Any]
    def matcher(*array_matchers, **keyword_matchers, &fn)
      Qo::GuardBlockMatcher.new(*array_matchers, **keyword_matchers, &fn)
    end

    alias_method :m, :matcher


    # Takes a set of Guard Block matchers, runs each in sequence, then
    # unfolds the response from the first passing block.
    #
    # @param target       [Any]                      Target object to run against
    # @param *qo_matchers [Array[GuardBlockMatcher]] Collection of matchers to run
    #
    # @return [type] [description]
    def match(target, *qo_matchers)
      all_are_guards = qo_matchers.all? { |q| q.is_a?(Qo::GuardBlockMatcher) }
      raise 'Must patch Qo GuardBlockMatchers!' unless all_are_guards

      qo_matchers.reduce(nil) { |_, matcher|
        did_match, match_result = matcher.call(target)
        break match_result if did_match
      }
    end

    # Wraps match to allow it to be used in a points-free style like regular matchers.
    #
    # @param *qo_matchers [Array[GuardBlockMatcher]] Collection of matchers to run
    #
    # @return [Proc[Any]]
    #     Any -> Any
    def match_fn(*qo_matchers)
      -> target { match(target, *qo_matchers) }
    end

    def and(*array_matchers, **keyword_matchers)
      Qo::Matcher.new('and', *array_matchers, **keyword_matchers)
    end

    alias_method :[], :and

    def or(*array_matchers, **keyword_matchers)
      Qo::Matcher.new('or', *array_matchers, **keyword_matchers)
    end

    def not(*array_matchers, **keyword_matchers)
      Qo::Matcher.new('not', *array_matchers, **keyword_matchers)
    end

    # Utility functions. Consider placing these elsewhere.

    def dig(path_map, expected_value)
      -> hash {
        segments = path_map.split('.')

        expected_value === hash.dig(*segments) ||
        expected_value === hash.dig(*segments.map(&:to_sym))
      }
    end

    def count_by(targets, &fn)
      fn ||= -> v { v }

      targets.each_with_object(Hash.new(0)) { |target, counts|
        counts[fn[target]] += 1
      }
    end
  end
end
