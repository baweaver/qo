require 'qo/exceptions'

module Qo
  module PatternMatchers
    # Creates a PatternMatch in a succinct block format:
    #
    # ```ruby
    # Qo.match(target) { |m|
    #   m.when(/^F/, 42) { |(name, age)| "#{name} is #{age}" }
    #   m.else { "We need a default, right?" }
    # }
    # ```
    #
    # The Public API obscures the fact that the matcher is only called when it
    # is explicitly given an argument to match against. If it is not, it will
    # just return a class waiting for a target, as such:
    #
    # ```ruby
    # def get_url(url)
    #   Net::HTTP.get_response(URI(url)).yield_self(&Qo.match { |m|
    #     m.when(Net::HTTPSuccess) { |response| response.body.size }
    #     m.else { |response| raise response.message }
    #   })
    # end
    #
    # get_url('https://github.com/baweaver/qo')
    # # => 142387
    # get_url('https://github.com/baweaver/qo/does_not_exist')
    # # => RuntimeError: Not Found
    # ```
    #
    # This is intended for flexibility between singular calls and calls as a
    # paramater to higher order functions like `map` and `yield_self`.
    #
    # This variant was inspired by ideas from Scala, Haskell, and various Ruby
    # libraries dealing with Async and self-yielding blocks. Especially notable
    # were websocket handlers and dry-ruby implementations.
    #
    # @author baweaver
    # @since 0.3.0
    #
    class BasePatternMatch
      def initialize
        @matchers = []

        yield(self)
      end

      # Creates a match case. This is the exact same as any other `and` style
      # match reflected in the public API, except that it's a Guard Block
      # match being performed. That means if the left side matches, the right
      # side function is invoked and that value is returned.
      #
      # @param *array_matchers [Array[Any]]
      #   Array style matchers
      #
      # @param **keyword_matchers [Hash[Any, Any]]
      #   Hash style matchers
      #
      # @param &fn [Proc]
      #   If matched, this function will be called. If no function is provided
      #   Qo will default to identity
      #
      # @return [Array[GuardBlockMatcher]]
      #   The return of this method should not be directly depended on, but will
      #   provide all matchers currently present. This will likely be left for
      #   ease of debugging later.
      def when(*array_matchers, **keyword_matchers, &fn)
        @matchers << Qo::Matchers::GuardBlockMatcher.new(
          array_matchers,
          keyword_matchers,
          &(fn || Qo::IDENTITY)
        )
      end

      # Else is the last statement that will be evaluated if all other parts
      # fail. It should be noted that it won't magically appear, you have to
      # explicitly put an `else` case in for it to catch on no match unless
      # you want a `nil` return
      #
      # @param &fn [Proc]
      #   Function to call when all other matches have failed. If no value is
      #   provided, it assumes `Qo::IDENTITY` which will return the value given.
      #
      # @return [Proc]
      def else(&fn)
        raise Qo::Exceptions::MultipleElseClauses if @else

        @else = fn || Qo::IDENTITY
      end

      # Proc version of a PatternMatch
      #
      # @return [Proc]
      #     Any -> Any | nil
      def to_proc
        Proc.new { |target| self.call(target) }
      end

      # Immediately invokes a PatternMatch
      #
      # @param target [Any]
      #   Target to run against and pipe to the associated block if it
      #   "matches" any of the GuardBlocks
      #
      # @return [Any]
      #   Result of the piped block
      #
      # @return [nil]
      #   No matches were found, so nothing is returned
      def call(target)
        @matchers.each { |guard_block_matcher|
          next unless guard_block_matcher.match?(target)
          return guard_block_matcher.match(target)
        }

        return @else.call(target) if @else

        nil
      end

      alias_method :===, :call
      alias_method :[], :call
    end
  end
end
