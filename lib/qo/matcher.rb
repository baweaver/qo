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
      -> match_target {
        return true if matchers == match_target

        match_target.is_a?(::Array) ?
          match_with(matchers.each_with_index, array_against_array_matcher(match_target)) :
          match_with(matchers, array_against_object_matcher(match_target))
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
      -> match_target {
        return true if matchers == match_target

        match_target.is_a?(::Hash) ?
          match_with(matchers, hash_against_hash_matcher(match_target)) :
          match_with(matchers, hash_against_object_matcher(match_target))
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
      -> matcher, i {
        wildcard_match(matcher) ||
        case_match(match_target[i], matcher) ||
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
      -> matcher {
        wildcard_match(matcher) ||
        case_match(match_target, matcher) ||
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
      -> match_key, match_value {
        return false unless match_target.key?(match_key)

        # If both the match value and target are hashes, descend if the key exists
        if match_value.is_a?(Hash) && match_target.is_a?(Hash)
          return match_against_hash(match_value)[match_target[match_key]]
        end

        wildcard_match(match_value) ||
        case_match(match_target[match_key], match_value)  ||
        method_matches?(match_target[match_key], match_value) || (
          # This is done for JSON responses, but as key can be `Any` we don't want to assume it knows how
          # to coerce `to_s` either. It's more of a nicety function.
          match_key.respond_to?(:to_s) &&
          match_target.key?(match_key.to_s) &&
          case_match(match_target[match_key.to_s], match_value)
        )
      }
    end

    # A function to match against an Object using a Hash
    #
    # @param match_target [Any] Target object
    #
    # @return [Proc]
    #     Any -> Any -> Bool # Matches against wildcard or match value versus the public send return of the target
    private def hash_against_object_matcher(match_target)
      -> match_key, match_value {
        return false unless match_target.respond_to?(match_key)

        wildcard_match(match_value) ||
        case_match(method_send(match_target, match_key), match_value) ||
        method_matches?(method_send(match_target, match_key), match_value)
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
    private def wildcard_match(value)
      value == WILDCARD_MATCH rescue false
    end

    # Wraps a case equality statement to make it a bit easier to read. The
    # typical left bias of `===` can be confusing reading down a page, so
    # more of a clarity thing than anything. Also makes for nicer stack traces.
    #
    # @param target [Any] Target to match against
    # @param value [respond_to?(:===)]
    #   Anything that responds to ===, preferably in a unique and entertaining way.
    #
    # @return [Boolean]
    private def case_match(target, value)
      value === target
    end
  end
end
