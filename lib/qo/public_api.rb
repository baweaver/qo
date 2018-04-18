module Qo
  # The Public API consists of methods that should be openly accessible to the
  # top level Qo namespace, and should not change. It should be used as the
  # subject of Acceptance level tests for the library and should not have its
  # externally facing methods renamed or moved under pain of a look of profound
  # disappointment from the creator.
  #
  # @author baweaver
  # @since 0.2.0
  #
  module PublicApi
    include Qo::Exceptions

    # Creates an `and` type query matcher. All conditions in this type of matcher
    # must pass to be considered a "match". It will short-circuit in the case of
    # a false match.
    #
    # @param *array_matchers    [Array] Array-like conditionals
    # @param **keyword_matchers [Hash]  Keyword style conditionals
    #
    # @return [Proc[Any]]
    #     Any -> Bool # Given a target, will return if it "matches"
    def and(*array_matchers, **keyword_matchers)
      create_matcher('and', array_matchers, keyword_matchers)
    end

    # The magic that lets you use `Qo[...]` instead of `Qo.and(...)`. Use wisely
    alias_method :[], :and

    # Creates an `or` type query matcher. Any conditions in this type of matcher
    # must pass to be considered a "match". It will short-circuit in the case of
    # a true match.
    #
    # @param *array_matchers    [Array] Array-like conditionals
    # @param **keyword_matchers [Hash]  Keyword style conditionals
    #
    # @return [Proc[Any]]
    #     Any -> Bool # Given a target, will return if it "matches"
    def or(*array_matchers, **keyword_matchers)
      create_matcher('or', array_matchers, keyword_matchers)
    end

    # Creates a `not` type query matcher. No conditions in this type of matcher
    # should pass to be considered a "match". It will short-circuit in the case of
    # a true match.
    #
    # @param *array_matchers    [Array] Array-like conditionals
    # @param **keyword_matchers [Hash]  Keyword style conditionals
    #
    # @return [Proc[Any]]
    #     Any -> Bool # Given a target, will return if it "matches"
    def not(*array_matchers, **keyword_matchers)
      create_matcher('not', array_matchers, keyword_matchers)
    end

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
      Qo::Matchers::GuardBlockMatcher.new(*array_matchers, **keyword_matchers, &fn)
    end

    # Might be a tinge fond of shorthand
    alias_method :m, :matcher

    # "Curried" function that waits for a target, or evaluates immediately if given
    # one.
    #
    # A PatternMatch will try and run all GuardBlock matchers in sequence until
    # it finds one that "matches". Once found, it will pass the target into the
    # associated matcher's block function.
    #
    # @param *args [Array[Any, *GuardBlockMatcher]]
    #   Collection of matchers to run, potentially prefixed by a target object
    #
    # @return [Qo::PatternMatch | Any]
    #   Returns a PatternMatch waiting for a target, or an evaluated PatternMatch response
    def match(*args)
      if args.first.is_a?(Qo::Matchers::GuardBlockMatcher)
        Qo::Matchers::PatternMatch.new(*args)
      else
        match_target, *qo_matchers = args
        Qo::Matchers::PatternMatch.new(*qo_matchers).call(match_target)
      end
    end

    # Abstraction for creating a matcher, allowing for common error handling scenarios.
    #
    # @param type [String] Type of matcher
    # @param *array_matchers [Array] Array-like conditionals
    # @param **keyword_matchers [Hash] Keyword style conditionals
    #
    # @raises Qo::Exceptions::NoMatchersProvided
    # @raises Qo::Exceptions::MultipleMatchersProvided
    #
    # @return [Qo::Matcher]
    private def create_matcher(type, array_matchers, keyword_matchers)
      array_empty, hash_empty = array_matchers.empty?, keyword_matchers.empty?

      raise Qo::NoMatchersProvided       if array_empty && hash_empty
      raise Qo::MultipleMatchersProvided if !(array_empty || hash_empty)

      if hash_empty
        Qo::Matchers::ArrayMatcher.new(type, *array_matchers)
      else
        Qo::Matchers::HashMatcher.new(type, **keyword_matchers)
      end
    end
  end
end
