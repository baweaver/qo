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
      @array_matchers.empty? ?
        match_against_hash(@keyword_matchers) :
        match_against_array(@array_matchers)
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
        match_target.is_a?(::Array) ?
          matchers.each_with_index.public_send(@match_method, &array_matches_array_fn(match_target)) :
          matchers.public_send(@match_method, &array_matches_object_fn(match_target))
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
        match_target.is_a?(::Hash) ?
          matchers.public_send(@match_method, &hash_matches_hash_fn(match_target)) :
          matchers.public_send(@match_method, &hash_matches_object_fn(match_target))
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
    private def array_matches_array_fn(match_target)
      -> matcher, i {
        matcher == WILDCARD_MATCH || matcher === match_target[i]
      }
    end

    # A function to match against an object using an array of predicates
    #
    # @param match_target [Any] Target object
    #
    # @return [Proc]
    #     String | Symbol -> Bool # Match against wildcard or boolean return of a predicate method
    private def array_matches_object_fn(match_target)
      -> matcher {
        matcher == WILDCARD_MATCH || match_target.public_send(matcher)
      }
    end

    # A function to match against a Hash using a Hash
    #
    # @param match_target [Hash[Any, Any]] Target Hash
    #
    # @return [Proc]
    #     Any -> Any -> Bool # Matches against wildcard or a key and value. Coerces key to_s if no matches for JSON.
    private def hash_matches_hash_fn(match_target)
      -> match_key, match_value {
        match_value == WILDCARD_MATCH ||
        match_value === match_target[match_key] || (
          # This is done for JSON responses, but as key can be `Any` we don't want to assume it knows how
          # to coerce `to_s` either. It's more of a nicety function.
          match_key.respond_to?(:to_s) &&
          match_value === match_target[match_key.to_s]
        )
      }
    end

    # A function to match against an Object using a Hash
    #
    # @param match_target [Any] Target object
    #
    # @return [Proc]
    #     Any -> Any -> Bool # Matches against wildcard or match value versus the public send return of the target
    private def hash_matches_object_fn(match_target)
      -> match_key, match_value {
        match_value == WILDCARD_MATCH || match_value === match_target.public_send(match_key)
      }
    end
  end
end
