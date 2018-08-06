module Qo
  # A Qo Matcher is a class that acts like a Proc. It takes in a set of match
  # values or key value pairs and a target value to evaluate against, and returns
  # the status of that match.
  #
  # It is possible to override this behavior via `to_proc` overloading and
  # utilization of `super` as noted in `GuardBlockMatcher`.
  #
  # @see Qo::Matchers::GuardBlockMatcher
  #
  # @author baweaver
  # @since 0.2.0
  #
  module Matchers
    # Base instance of matcher which is meant to take in either Array style or
    # Keyword style arguments to run a match against various datatypes.
    #
    # Will delegate responsibilities to either Array or Hash style matchers if
    # invoked directly.
    #
    # @author baweaver
    # @since 0.2.0
    #
    class BaseMatcher
      def initialize(type, *array_matchers, **keyword_matchers)
        @array_matchers   = array_matchers
        @keyword_matchers = keyword_matchers
        @type             = type
      end

      # Converts a Matcher to a proc for use in querying, such as:
      #
      #     data.select(&Qo[...])
      #
      # @return [Proc[Any]]
      def to_proc
        @array_matchers.empty? ?
          Qo::Matchers::HashMatcher.new(@type, **@keyword_matchers).to_proc :
          Qo::Matchers::ArrayMatcher.new(@type, *@array_matchers).to_proc
      end

      # You can directly call a matcher as well, much like a Proc,
      # using one of call, ===, or []
      #
      # @param target [Any] Object to match against
      #
      # @return [Boolean] Result of the match
      def call(target)
        self.to_proc.call(target)
      end

      alias_method :===, :call
      alias_method :[],  :call

      # Runs the relevant match method against the given collection with the
      # given matcher function.
      #
      # @param collection [Enumerable] Any collection that can be enumerated over
      # @param fn         [Proc]       Function to match with
      #
      # @return [Boolean] Result of the match
      private def match_with(collection, &fn)
        return collection.any?(&fn)  if @type == 'or'
        return collection.none?(&fn) if @type == 'not'

        collection.all?(&fn)
      end

      # Wraps a case equality statement to make it a bit easier to read. The
      # typical left bias of `===` can be confusing reading down a page, so
      # more of a clarity thing than anything. Also makes for nicer stack traces.
      #
      # @param target  [Any]
      #   Target to match against
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
      # @param target  [Any] Object to send to
      # @param matcher [#to_sym] Anything that can be coerced into a method name
      #
      # @return [Any] Response of sending to the method, or false if failed
      private def method_send(target, matcher)
        matcher.respond_to?(:to_sym) &&
        target.respond_to?(matcher.to_sym) &&
        target.public_send(matcher)
      end

      # Predicate variant of `method_send` with the same guard concerns
      #
      # @param target  [Any]     Object to send to
      # @param matcher [#to_sym] Anything that can be coerced into a method name
      #
      # @return [Boolean] Success status of predicate
      private def method_matches?(target, matcher)
        !!method_send(target, matcher)
      end
    end
  end
end
