module Qo
  module Matchers
    # An Array Matcher is a matcher that uses only `*varargs` to define a sequence
    # of matches to perform against either an object or another Array.
    #
    # In the case of an Array matching against an Array it will compare via index.
    #
    # ```ruby
    # # Shorthand
    # Qo[1..10, 1..10].call([1, 2])
    # # => true
    #
    # Qo::Matchers::ArrayMatcher.new([1..10, 1..10]).call([1, 2])
    # # => true
    # ```
    #
    # In the case of an Array matching against an Object, it will match each provided
    # matcher against the object.
    #
    # ```ruby
    # # Shorthand
    # Qo[Integer, 1..10].call(1)
    # # => true
    #
    # Qo::Matchers::ArrayMatcher.new([1..10, 1..10]).call(1)
    # # => true
    # ```
    #
    # All variants present in the BaseMatcher are present here, including 'and',
    # 'not', and 'or'.
    #
    # @author baweaver
    # @since 0.2.0
    #
    class ArrayMatcher < BaseMatcher
      # Wrapper around call to allow for invocation in an Enumerable function,
      # such as:
      #
      # ```ruby
      # people.select(&Qo[/Foo/, 20..40])
      # ```
      #
      # @return [Proc[Any]]
      #   Proc awaiting a target to match against
      def to_proc
        Proc.new { |target| self.call(target) }
      end

      # Runs the matcher directly.
      #
      # If the target is an Array, it will be matched via index
      #
      # If the target is an Object, it will be matched via public send
      #
      # @param target [Any] Target to match against
      #
      # @return [Boolean] Result of the match
      def call(target)
        return true if @array_matchers == target

        if target.is_a?(::Array)
          match_with(@array_matchers.each_with_index) { |matcher, i|
            match_value?(target[i], matcher)
          }
        else
          match_with(@array_matchers) { |matcher|
            match_value?(target, matcher)
          }
        end
      end

      # Defines what it means for a value to match a matcher
      #
      # @param target  [Any] Target to match against
      # @param matcher [Any] Any matcher to run against, most frequently responds to ===
      #
      # @return [Boolean] Match status
      private def match_value?(target, matcher)
        case_match?(target, matcher) ||
        method_matches?(target, matcher)
      end
    end
  end
end
