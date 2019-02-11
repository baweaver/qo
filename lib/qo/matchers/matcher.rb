module Qo
  module Matchers
    # Matcher used to determine whether a value matches a certain set of
    # conditions
    #
    # @author baweaver
    # @since 1.0.0
    #
    class Matcher
      # Creates a new matcher
      #
      # @param type [String]
      #   Type of the matcher: any, all, or none. Used to determine how a
      #   match is determined
      #
      # @param array_matchers = [] [Array[Any]]
      #   Conditions given as an array
      #
      # @param keyword_matchers = {} [Hash[Any, Any]]
      #   Conditions given as keywords
      #
      # @return [Qo::Matchers::Matcher]
      def initialize(type, array_matchers = [], keyword_matchers = {})
        @type = type
        @array_matchers = array_matchers
        @keyword_matchers = keyword_matchers
      end

      # Proc-ified version of `call`
      #
      # @return [Proc[Any] => Boolean]
      def to_proc
        -> target { self.call(target) }
      end

      # Calls the matcher on a given target value
      #
      # @param target [Any]
      #   Target to match against
      #
      # @return [Boolean]
      #   Whether or not the target matched
      def call(target)
        combined_check(array_call(target), keyword_call(target))
      end

      alias_method :===, :call
      alias_method :[],  :call
      alias_method :match?,  :call

      # Used to match against a matcher made from Keyword Arguments (a Hash)
      #
      # @param matchers [Hash[Any, #===]]
      #   Any key mapping to any value that responds to `===`. Notedly more
      #   satisfying when `===` does something fun.
      #
      # @return [Boolean]
      #   Result of the match
      private def keyword_call(target)
        return true if @keyword_matchers == target

        match_fn = target.is_a?(::Hash) ?
          Proc.new { |match_key, matcher| match_hash_value?(target, match_key, matcher)   } :
          Proc.new { |match_key, matcher| match_object_value?(target, match_key, matcher) }

        match_with(@keyword_matchers, &match_fn)
      end

      # Runs the matcher directly.
      #
      # If the target is an Array, it will be matched via index
      #
      # If the target is an Object, it will be matched via public send
      #
      # @param target [Any]
      #   Target to match against
      #
      # @return [Boolean]
      #   Result of the match
      private def array_call(target)
        return true if @array_matchers == target

        if target.is_a?(::Array)
          return false unless target.size == @array_matchers.size

          match_with(@array_matchers.each_with_index) { |matcher, i|
            match_value?(target[i], matcher)
          }
        else
          match_with(@array_matchers) { |matcher|
            match_value?(target, matcher)
          }
        end
      end

      # Wraps a case equality statement to make it a bit easier to read. The
      # typical left bias of `===` can be confusing reading down a page, so
      # more of a clarity thing than anything. Also makes for nicer stack traces.
      #
      # @param target  [Any]
      #   Target to match against
      #
      # @param matcher [#===]
      #   Anything that responds to ===, preferably in a unique and entertaining way.
      #
      # @return [Boolean]
      private def case_match?(target, matcher)
        matcher === target
      end

      # Guarded version of `public_send` meant to stamp out more
      # obscure errors when running against non-matching types.
      #
      # @param target  [Any]
      #   Object to send to
      #
      # @param matcher [#to_sym]
      #   Anything that can be coerced into a method name
      #
      # @return [Any]
      #   Response of sending to the method, or false if failed
      private def method_send(target, matcher)
        matcher.respond_to?(:to_sym) &&
        target.respond_to?(matcher.to_sym) &&
        target.public_send(matcher)
      end

      # Predicate variant of `method_send` with the same guard concerns
      #
      # @param target [Any]
      #   Object to send to
      #
      # @param matcher [#to_sym]
      #   Anything that can be coerced into a method name
      #
      # @return [Boolean]
      #   Success status of predicate
      private def method_matches?(target, matcher)
        !!method_send(target, matcher)
      end

      # Defines what it means for a value to match a matcher
      #
      # @param target [Any]
      #   Target to match against
      #
      # @param matcher [Any]
      #   Any matcher to run against, most frequently responds to ===
      #
      # @return [Boolean]
      #   Match status
      private def match_value?(target, matcher)
        case_match?(target, matcher) ||
        method_matches?(target, matcher)
      end

      # Checks if a hash value matches a given matcher
      #
      # @param target [Any]
      #   Target of the match
      #
      # @param match_key [Symbol]
      #   Key of the hash to reference
      #
      # @param matcher [#===]
      #   Any matcher responding to ===
      #
      # @return [Boolean]
      #   Match status
      private def match_hash_value?(target, match_key, matcher)
        return false unless target.key?(match_key)

        return hash_recurse(target[match_key], matcher) if target.is_a?(Hash) && matcher.is_a?(Hash)

        hash_case_match?(target, match_key, matcher) ||
        hash_method_predicate_match?(target, match_key, matcher)
      end

      # Checks if an object property matches a given matcher
      #
      # @param target [Any]
      #   Target of the match
      #
      # @param match_property [Symbol]
      #   Property of the object to reference
      #
      # @param matcher [#===]
      #   Any matcher responding to ===
      #
      # @return [Boolean] Match status
      private def match_object_value?(target, match_property, matcher)
        return false unless target.respond_to?(match_property)

        hash_method_case_match?(target, match_property, matcher)
      end

      # Double wraps case match in order to ensure that we try against both Symbol
      # and String variants of the keys, as this is a very common mixup in Ruby.
      #
      # @param target [Hash]
      #   Target of the match
      #
      # @param match_key [Symbol]
      #   Key to match against
      #
      # @param matcher [#===]
      #   Matcher
      #
      # @return [Boolean]
      private def hash_case_match?(target, match_key, matcher)
        return true if case_match?(target[match_key], matcher)
        return false unless target.keys.first.is_a?(String)

        match_key.respond_to?(:to_s) &&
        target.key?(match_key.to_s) &&
        case_match?(target[match_key.to_s], matcher)
      end

      # Attempts to run a matcher as a predicate method against the target
      #
      # @param target [Hash]
      #   Target of the match
      #
      # @param match_key [Symbol]
      #   Method to call
      #
      # @param match_predicate [Symbol]
      #   Matcher
      #
      # @return [Boolean]
      private def hash_method_predicate_match?(target, match_key, match_predicate)
        method_matches?(target[match_key], match_predicate)
      end

      # Attempts to run a case match against a method call derived from a hash
      # key, and checks the result.
      #
      # @param target [Hash]
      #   Target of the match
      #
      # @param match_property [Symbol]
      #   Method to call
      #
      # @param matcher [#===]
      #   Matcher
      #
      # @return [Boolean]
      private def hash_method_case_match?(target, match_property, matcher)
        case_match?(method_send(target, match_property), matcher)
      end

      # Recurses on nested hashes.
      #
      # @param target [Hash]
      #   Target to recurse into
      #
      # @param matcher [Hash]
      #   Matcher to use to recurse with
      #
      # @return [Boolean]
      private def hash_recurse(target, matcher)
        Qo::Matchers::Matcher.new(@type, [], matcher).call(target)
      end

      # Runs the relevant match method against the given collection with the
      # given matcher function.
      #
      # @param collection [Enumerable] Any collection that can be enumerated over
      # @param fn         [Proc]       Function to match with
      #
      # @return [Boolean] Result of the match
      private def match_with(collection, &fn)
        case @type
        when 'and' then collection.all?(&fn)
        when 'or'  then collection.any?(&fn)
        when 'not' then collection.none?(&fn)
        else false
        end
      end

      # When combining array and keyword type matchers, depending on how
      # we're matching we may need to combine them slightly differently.
      #
      # @param *checks [Array]
      #   The checks we're combining
      #
      # @return [Boolean]
      #   Whether or not there's a match
      private def combined_check(*checks)
        case @type
        when 'and', 'not' then checks.all?
        when 'or'         then checks.any?
        else false
        end
      end
    end
  end
end
