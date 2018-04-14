module Qo
  class Matcher
    def initialize(type, *array_matchers, **keyword_matchers)
      @match_method     = get_match_method(type)
      @array_matchers   = array_matchers
      @keyword_matchers = keyword_matchers
    end

    # Converts a Matcher to a proc for use in querying, such as:
    #
    #     data.select(&Qo[...])
    #
    # @return [Proc]
    def to_proc
      if @array_matchers.empty?
        match_against_hash(@keyword_matchers)
      else
        match_against_array(@array_matchers)
      end
    end

    # You can directly call a matcher as well, much like a Proc,
    # using one of call, ===, or []
    #
    # @param match_target [Any] Object to match against
    #
    # @return [type] [description]
    def call(match_target)
      self.to_proc.call(match_target)
    end

    alias_method :===, :call
    alias_method :[],  :call

    # Used to match against a matcher made from an Array, like:
    #
    #     Qo['Foo', 'Bar']
    #
    # @param matchers [Array[respond_to?(===)]] indexed tuple to match the target object against
    #
    # @return [Proc[Any]]
    #     Array  -> Bool # Tuple match against targets index
    #     Object -> Bool # Boolean public send
    private def match_against_array(matchers)
      Proc.new { |match_target|
        next true if matchers == match_target

        if match_target.is_a?(::Array)
          match_collection = matchers.each_with_index
          match_fn         = array_against_array_matcher(match_target)
        else
          match_collection = matchers
          match_fn         = array_against_object_matcher(match_target)
        end

        match_with(match_collection, match_fn)
      }
    end

    # Used to match against a matcher made from Keyword Arguments (a Hash)
    #
    # @param matchers [Hash[Any, respond_to?(===)]]
    #     Any key mapping to any value that responds to `===`. Notedly more
    #     satisfying when `===` does something fun.
    #
    # @return [Proc[Any]]
    #     Hash   -> Bool # Value matching against similar keys, will attempt to coerce to_s because JSON
    #     Object -> Bool # Uses keys as methods with public send to `===` match against the value
    private def match_against_hash(matchers)
      Proc.new { |match_target|
        next true if matchers == match_target

        match_fn = match_target.is_a?(::Hash) ?
          hash_against_hash_matcher(match_target) :
          hash_against_object_matcher(match_target)

        match_with(matchers, match_fn)
      }
    end

    # Used to map the nicety names against the actual Ruby methods they represent
    #
    # @param name [String] Query type name
    #
    # @return [Symbol] The method name to use to query with
    private def get_match_method(name)
      case name
      when 'and' then :all?
      when 'or'  then :any?
      when 'not' then :none?
      else :all?
      end
    end

    # A function to match against an indexed array tuple
    #
    # @param match_target [Array] Target array
    #
    # @return [Proc]
    #     Any -> Int -> Bool # Match against wildcard or same position in target array
    private def array_against_array_matcher(match_target)
      Proc.new { |matcher, i|
        wildcard_match?(matcher) ||
        case_match?(match_target[i], matcher) ||
        method_matches?(match_target[i], matcher)
      }
    end

    # A function to match against an object using an array of predicates
    #
    # @param match_target [Any] Target object
    #
    # @return [Proc]
    #     String | Symbol -> Bool # Match against wildcard or boolean return of a predicate method
    private def array_against_object_matcher(match_target)
      Proc.new { |matcher|
        wildcard_match?(matcher) ||
        case_match?(match_target, matcher) ||
        method_matches?(match_target, matcher)
      }
    end

    # A function to match against a Hash using a Hash
    #
    # @param match_target [Hash[Any, Any]] Target Hash
    #
    # @return [Proc]
    #     Any -> Any -> Bool # Matches against wildcard or a key and value. Coerces key to_s if no matches for JSON.
    private def hash_against_hash_matcher(match_target)
      Proc.new { |(match_key, match_value)|
        next true if hash_wildcard_match?(match_target, match_key, match_value)

        next hash_recurse(match_target[match_key], match_value) if hash_should_recurse?(match_target, match_value)

        hash_case_match?(match_target, match_key, match_value) ||
        hash_method_case_match?(match_target, match_key, match_value)
      }
    end

    # A function to match against an Object using a Hash
    #
    # @param match_target [Any] Target object
    #
    # @return [Proc]
    #     Any -> Any -> Bool # Matches against wildcard or match value versus the public send return of the target
    private def hash_against_object_matcher(match_target)
      Proc.new { |(match_key, match_value)|
        object_wildcard_match?(match_target, match_key, match_value) ||
        hash_method_case_match?(match_target, match_key, match_value)
      }
    end

    # Wrapper around public send to encapsulate the matching method (any, all, none)
    #
    # @param collection [Enumerable] Any collection that can be enumerated over
    # @param fn         [Proc] Function to match with
    #
    # @return [Enumerable] Resulting collection
    private def match_with(collection, fn)
      collection.public_send(@match_method, &fn)
    end

    # Predicate variant of `method_send` with the same guard concerns
    #
    # @param target  [Any] Object to send to
    # @param matcher [respond_to?(:to_sym)] Anything that can be coerced into a method name
    #
    # @return [Boolean] Success status of predicate
    private def method_matches?(target, matcher)
      !!method_send(target, matcher)
    end

    # Guarded version of `public_send` meant to stamp out more
    # obscure errors when running against non-matching types.
    #
    # @param target  [Any] Object to send to
    # @param matcher [respond_to?(:to_sym)] Anything that can be coerced into a method name
    #
    # @return [Any] Response of sending to the method, or false if failed
    private def method_send(target, matcher)
      matcher.respond_to?(:to_sym) &&
      target.respond_to?(matcher.to_sym) &&
      target.public_send(matcher)
    end

    # Wraps wildcard in case we want to do anything fun with it later
    #
    # @param value [Any] Value to test against the wild card
    #
    # @note The rescue is because some classes override `==` to do silly things,
    #       like IPAddr, and I kinda want to use that.
    #
    # @return [Boolean]
    private def wildcard_match?(value)
      value == WILDCARD_MATCH rescue false
    end

    # Wraps strict checks on keys with a wildcard match
    #
    # @param match_target [Hash]
    # @param match_key    [Symbol]
    # @param match_value  [Any]
    #
    # @return [Boolean]
    private def hash_wildcard_match?(match_target, match_key, match_value)
      return false unless match_target.key?(match_key)

      wildcard_match?(match_value)
    end

    # Wraps strict checks for methods existing on objects with a wildcard match
    #
    # @param match_target [Hash]
    # @param match_key    [Symbol]
    # @param match_value  [Any]
    #
    # @return [Boolean]
    private def object_wildcard_match?(match_target, match_key, match_value)
      return false unless match_target.respond_to?(match_key)

      wildcard_match?(match_value)
    end

    # Wraps a case equality statement to make it a bit easier to read. The
    # typical left bias of `===` can be confusing reading down a page, so
    # more of a clarity thing than anything. Also makes for nicer stack traces.
    #
    # @param match_target [Any] Target to match against
    # @param match_value  [respond_to?(:===)]
    #   Anything that responds to ===, preferably in a unique and entertaining way.
    #
    # @return [Boolean]
    private def case_match?(match_target, match_value)
      match_value === match_target
    end

    # Double wraps case match in order to ensure that we try against both Symbol
    # and String variants of the keys, as this is a very common mixup in Ruby.
    #
    # @param match_target [Hash]              Target of the match
    # @param match_key    [Symbol]            Key to match against
    # @param match_value  [respond_to?(:===)] Matcher
    #
    # @return [Boolean]
    private def hash_case_match?(match_target, match_key, match_value)
      return true if case_match?(match_target[match_key], match_value)

      match_key.respond_to?(:to_s) &&
      match_target.key?(match_key.to_s) &&
      case_match?(match_target[match_key.to_s], match_value)
    end

    # Attempts to run a case match against a method call derived from a hash
    # key, and checks the result.
    #
    # @param match_target [Hash]              Target of the match
    # @param match_key    [Symbol]            Method to call
    # @param match_value  [respond_to?(:===)] Matcher
    #
    # @return [Boolean]
    private def hash_method_case_match?(match_target, match_key, match_value)
      case_match?(method_send(match_target, match_key), match_value)
    end

    # Defines preconditions for Hash recursion in matching. Currently it's
    # only Hash and Hash, but may expand later to Arrays and other Enums.
    #
    # @param match_target [Any]
    # @param match_value  [Any]
    #
    # @return [Boolean]
    private def hash_should_recurse?(match_target, match_value)
      match_target.is_a?(Hash) && match_value.is_a?(Hash)
    end

    # Recurses on nested hashes.
    #
    # @param match_target [Hash]
    # @param match_value  [Hash]
    #
    # @return [Boolean]
    private def hash_recurse(match_target, match_value)
      match_against_hash(match_value).call(match_target)
    end
  end
end
