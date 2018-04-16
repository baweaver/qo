module Qo
  module Matchers
    # A Hash Matcher is a matcher that uses only keyword args to define a sequence
    # of matches to perform against either an Object or another Hash.
    #
    # In the case of a Hash matching against a Hash, it will compare the intersection
    # of keys and match the values against eachother.
    #
    # In the case of a Hash matching against an Object, it will treat the keys as
    # method property invocations to be matched against the provided values.
    #
    # All variants present in the BaseMatcher are present here, including 'and',
    # 'not', and 'or'.
    #
    # @author [baweaver]
    #
    class HashMatcher < BaseMatcher
      # Used to match against a matcher made from an Array, like:
      #
      #     Qo['Foo', 'Bar']
      #
      # @param matchers [Array[respond_to?(===)]] indexed tuple to match the target object against
      #
      # @return [Proc[Any]]
      #     Array  -> Bool # Tuple match against targets index
      #     Object -> Bool # Boolean public send
      def to_proc
        Proc.new { |target| self.call(target) }
      end

      # Used to match against a matcher made from Keyword Arguments (a Hash)
      #
      # @param matchers [Hash[Any, respond_to?(:===)]]
      #     Any key mapping to any value that responds to `===`. Notedly more
      #     satisfying when `===` does something fun.
      #
      # @return [Proc[Any]]
      #     Hash   -> Bool # Value matching against similar keys, will attempt to coerce to_s because JSON
      #     Object -> Bool # Uses keys as methods with public send to `===` match against the value
      def call(target)
        return true if @keyword_matchers == target

        match_fn = target.is_a?(::Hash) ?
          Proc.new { |match_key, matcher| match_hash_value?(target, match_key, matcher)   } :
          Proc.new { |match_key, matcher| match_object_value?(target, match_key, matcher) }

        match_with(@keyword_matchers, &match_fn)
      end

      # Checks if a hash value matches a given matcher
      #
      # @param target    [Any]               Target of the match
      # @param match_key [Symbol]            Key of the hash to reference
      # @param matcher   [respond_to?(:===)] Any matcher responding to ===
      #
      # @return [Boolean] Match status
      private def match_hash_value?(target, match_key, matcher)
        return false unless target.key?(match_key)
        return true if wildcard_match?(matcher)

        return hash_recurse(target[match_key], matcher) if target.is_a?(Hash) && matcher.is_a?(Hash)

        hash_case_match?(target, match_key, matcher) ||
        hash_method_predicate_match?(target, match_key, matcher)
      end

      # Checks if an object property matches a given matcher
      #
      # @param target         [Any]               Target of the match
      # @param match_property [Symbol]            Property of the object to reference
      # @param matcher        [respond_to?(:===)] Any matcher responding to ===
      #
      # @return [Boolean] Match status
      private def match_object_value?(target, match_property, matcher)
        return false unless target.respond_to?(match_property)

        wildcard_match?(matcher) ||
        hash_method_case_match?(target, match_property, matcher)
      end

      # Double wraps case match in order to ensure that we try against both Symbol
      # and String variants of the keys, as this is a very common mixup in Ruby.
      #
      # @param target    [Hash]              Target of the match
      # @param match_key [Symbol]            Key to match against
      # @param matcher   [respond_to?(:===)] Matcher
      #
      # @return [Boolean]
      private def hash_case_match?(target, match_key, matcher)
        return true if case_match?(target[match_key], matcher)

        match_key.respond_to?(:to_s) &&
        target.key?(match_key.to_s) &&
        case_match?(target[match_key.to_s], matcher)
      end

      # Attempts to run a matcher as a predicate method against the target
      #
      # @param target          [Hash]   Target of the match
      # @param match_key       [Symbol] Method to call
      # @param match_predicate [Symbol] Matcher
      #
      # @return [Boolean]
      private def hash_method_predicate_match?(target, match_key, match_predicate)
        method_matches?(target[match_key], match_predicate)
      end

      # Attempts to run a case match against a method call derived from a hash
      # key, and checks the result.
      #
      # @param target         [Hash]              Target of the match
      # @param match_property [Symbol]            Method to call
      # @param matcher        [respond_to?(:===)] Matcher
      #
      # @return [Boolean]
      private def hash_method_case_match?(target, match_property, matcher)
        case_match?(method_send(target, match_property), matcher)
      end

      # Recurses on nested hashes.
      #
      # @param target  [Hash]
      # @param matcher [Hash]
      #
      # @return [Boolean]
      private def hash_recurse(target, matcher)
        Qo::Matchers::HashMatcher.new(@type, **matcher).call(target)
      end
    end
  end
end
