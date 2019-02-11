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
    # @param *array_matchers [Array]
    #   Array-like conditionals
    #
    # @param **keyword_matchers [Hash]
    #   Keyword style conditionals
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
    # @param *array_matchers [Array]
    #   Array-like conditionals
    #
    # @param **keyword_matchers [Hash]
    #   Keyword style conditionals
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
    # @param *array_matchers [Array]
    #   Array-like conditionals
    #
    # @param **keyword_matchers [Hash]
    #   Keyword style conditionals
    #
    # @return [Proc[Any]]
    #     Any -> Bool # Given a target, will return if it "matches"
    def not(*array_matchers, **keyword_matchers)
      create_matcher('not', array_matchers, keyword_matchers)
    end

    # A pattern match will try and run all guard block style matchers in sequence
    # until it finds one that "matches". Once found, it will pass the target
    # into the associated matcher's block function.
    #
    # @example
    #   [1,2,3].map(&Qo.match { |m|
    #     m.when(:even?) { |v| v * 3 }
    #     m.else         { |v| v - 1 }
    #   })
    #   => [0, 6, 2]
    #
    # @param fn [Proc]
    #   Body of the matcher, as shown in examples
    #
    # @return [Qo::PatternMatch]
    #   A function awaiting a value to match against
    def match(destructure: false, &fn)
      return proc { false } unless block_given?

      Qo::PatternMatchers::PatternMatch.new(destructure: destructure, &fn)
    end

    def result_match(destructure: false, &fn)
      return proc { false } unless block_given?

      Qo::PatternMatchers::ResultPatternMatch.new(destructure: destructure, &fn)
    end

    def result_case(target, destructure: false, &fn)
      Qo::PatternMatchers::ResultPatternMatch.new(destructure: destructure, &fn).call(target)
    end

    # Similar to the common case statement of Ruby, except in that it behaves
    # as if `Array#===` and `Hash#===` exist in the form of Qo matchers.
    #
    # @note
    #   I refer to the potential 2.6+ features currently being discussed here:
    #
    #   * `Hash#===`  - https://bugs.ruby-lang.org/issues/14869
    #   * `Array#===` - https://bugs.ruby-lang.org/issues/14916
    #
    # @see Qo#match
    #
    # @example
    #   Qo.case([1, 1]) { |m|
    #     m.when(Any, Any) { |a, b| a + b }
    #     m.else { |v| v }
    #   }
    #   => 2
    #
    # @param value [Any]
    #   Value to match against
    #
    # @param &fn [Proc]
    #   Body of the matcher, as shown above
    #
    # @return [Any]
    #   The result of calling a pattern match with a provided value
    def case(value, destructure: false, &fn)
      Qo::PatternMatchers::PatternMatch.new(destructure: destructure, &fn).call(value)
    end

    def create_branch(name:, precondition: Any, extractor: IDENTITY, destructure: false, default: false)
      Qo::Branches::Branch.create(
        name:         name,
        precondition: precondition,
        extractor:    extractor,
        destructure:  destructure,
        default:      default
      )
    end

    def create_pattern_match(branches:)
      Qo::PatternMatchers::PatternMatch.create(branches: branches)
    end

    # Abstraction for creating a matcher.
    #
    # @param type [String]
    #   Type of matcher
    #
    # @param array_matchers [Array[Any]]
    #   Array-like conditionals
    #
    # @param keyword_matchers [Hash[Any, Any]]
    #   Keyword style conditionals
    #
    # @return [Qo::Matcher]
    private def create_matcher(type, array_matchers, keyword_matchers)
      Qo::Matchers::Matcher.new(type, array_matchers, keyword_matchers)
    end
  end
end
