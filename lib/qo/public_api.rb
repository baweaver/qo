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
    # @param destructure: [Boolean]
    #   Whether or not to destructure an object before yielding it to the
    #   given function.
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
    # @param destructure: [Boolean]
    #   Whether or not to destructure an object before yielding it to the
    #   given function.
    #
    # @param &fn [Proc]
    #   Body of the matcher, as shown above
    #
    # @return [Any]
    #   The result of calling a pattern match with a provided value
    def case(value, destructure: false, &fn)
      Qo::PatternMatchers::PatternMatch.new(destructure: destructure, &fn).call(value)
    end

    # Similar to `match`, except it uses a `ResultPatternMatch` which instead
    # responds to tuple types:
    #
    # @example
    #
    #   ```ruby
    #   pm = Qo.result_match { |m|
    #     m.success { |v| v + 10 }
    #     m.failure { |v| "Error: #{v}" }
    #   }
    #
    #   pm.call([:ok, 3])
    #   # => 13
    #
    #   pm.call([:err, "No Good"])
    #   # => "Error: No Good"
    #   ```
    #
    # @param destructure: [Boolean]
    #   Whether or not to destructure an object before yielding it to the
    #   given function.
    #
    # @param &fn [Proc]
    #   Body of the matcher, as shown above
    #
    # @see match
    #
    # @return [Proc[Any] => Any]
    #   Proc awaiting a value to match against.
    def result_match(destructure: false, &fn)
      return proc { false } unless block_given?

      Qo::PatternMatchers::ResultPatternMatch.new(destructure: destructure, &fn)
    end

    # Similar to `case`, except it uses a `ResultPatternMatch` instead.
    #
    # @see match
    # @see result_match
    # @see case
    #
    # @param target [Any]
    #   Target to match against
    #
    # @param destructure: [Boolean]
    #   Whether or not to destructure an object before yielding it to the
    #   given function.
    #
    # @param &fn [Proc]
    #   Body of the matcher, as shown above
    #
    # @return [Any]
    #   Result of the match
    def result_case(target, destructure: false, &fn)
      Qo::PatternMatchers::ResultPatternMatch
        .new(destructure: destructure, &fn)
        .call(target)
    end

    # Dynamically creates a new branch to be used with custom pattern matchers.
    #
    # @param name: [String]
    #   Name of the branch. This is what binds to the pattern match as a method,
    #   meaning a name of `where` will result in calling it as `m.where`.
    #
    # @param precondition: Any [Symbol, #===]
    #   A precondition to the branch being considered true. This is done for
    #   static conditions like a certain type or perhaps checking a tuple type
    #   like `[:ok, value]`.
    #
    #   If a `Symbol` is given, Qo will coerce it into a proc. This is done to
    #   make a nicer shorthand for creating a branch.
    #
    # @param extractor: IDENTITY [Proc, Symbol]
    #   How to pull the value out of a target object when a branch matches before
    #   calling the associated function. For a monadic type this might be something
    #   like extracting the value before yielding to the given block.
    #
    #   If a `Symbol` is given, Qo will coerce it into a proc. This is done to
    #   make a nicer shorthand for creating a branch.
    #
    # @param destructure: false
    #   Whether or not to destructure the given object before yielding to the
    #   associated block. This means that the given block now places great
    #   importance on the argument names, as they'll be used to extract values
    #   from the associated object by that same method name, or key name in the
    #   case of hashes.
    #
    # @param default: false [Boolean]
    #   Whether this branch is considered to be a default condition. This is
    #   done to ensure that a branch runs last after all other conditions have
    #   failed. An example of this would be an `else` branch.
    #
    # @return [Class]
    #   Anonymous branch class to be bound to a constant or used directly
    def create_branch(name:, precondition: Any, extractor: IDENTITY, destructure: false, default: false)
      Qo::Branches::Branch.create(
        name:         name,
        precondition: precondition,
        extractor:    extractor,
        destructure:  destructure,
        default:      default
      )
    end

    # Creates a new type of pattern matcher from a set of branches
    #
    # @param branches: [Array[Branch]]
    #   An array of branches that this pattern matcher will respond to
    #
    # @return [Class]
    #   Anonymous pattern matcher to be bound to a constant or used directly
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
