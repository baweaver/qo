module Qo
  module PatternMatchers
    # Classic Pattern Match. This matcher uses `when` and `else` branches and
    # is meant to be a more powerful variant of the case statement
    #
    # @author baweaver
    # @since 0.2.0
    class PatternMatch
      include Branching

      # All matchers that have currently been added to an instance
      # of a pattern match
      attr_reader :provided_matchers

      # The regular pattern matcher from classic Qo uses `when` and `else`
      # branches, like a `case` statement
      register_branch Qo::Branches::WhenBranch.new
      register_branch Qo::Branches::ElseBranch.new

      # Creates a new instance of a pattern matcher
      #
      # @param destructure: false [Boolean]
      #   Whether or not to destructure values before yielding to a block
      #
      # @param exhaustive: false [Boolean]
      #   If no matches are found, this will raise a
      #   `Qo::Errors::ExhaustiveMatchNotMet` error.
      #
      # @param &fn [Proc]
      #   Function to be used to construct the pattern matcher's branches
      #
      # @return [Qo::PatternMatchers::PatternMatch]
      def initialize(destructure: false, exhaustive: false, &fn)
        @matchers    = []
        @default     = nil
        @destructure = destructure
        @exhaustive  = exhaustive

        yield(self) if block_given?

        if lacking_branches?
          raise Qo::Exceptions::ExhaustiveMatchMissingBranches.new(
            expected_branches: available_branch_names,
            given_branches:    provided_matchers
          )
        end
      end

      # Allows for the creation of an anonymous PatternMatcher based on this
      # parent class. To be used by people wishing to make their own pattern
      # matchers with variant branches and other features not included in the
      # defaultly provided ones
      #
      # @param branches: [] [Array[Branch]]
      #   Branches to be used with this new pattern matcher
      #
      # @return [Class]
      #   Anonymous pattern matcher class to be bound to a constant or used
      #   anonymously.
      def self.create(branches: [])
        Class.new(Qo::PatternMatchers::PatternMatch) do
          branches.each { |branch| register_branch(branch.new) }
        end
      end

      # Allows for the injection of a pattern matching function into a type class
      # for direct access, rather than yielding an instance of that class to a
      # pattern matcher.
      #
      # This is typically done for monadic types that need to `match`. When
      # combined with extractor type branches it can be very handy for dealing
      # with container types.
      #
      # @example
      #
      #   ```ruby
      #   # Technically Some and None don't exist yet, so we have to "cheat" instead
      #   # of just saying `Some` for the precondition
      #   SomeBranch = Qo.create_branch(
      #     name:        'some',
      #     precondition: -> v { v.is_a?(Some) },
      #     extractor:    :value
      #   )
      #
      #   NoneBranch = Qo.create_branch(
      #     name:        'none',
      #     precondition: -> v { v.is_a?(None) },
      #     extractor:    :value
      #   )
      #
      #   SomePatternMatch = Qo.create_pattern_match(branches: [SomeBranch, NoneBranch])
      #
      #   class Some
      #     include SomePatternMatch.mixin
      #
      #     attr_reader :value
      #
      #     def initialize(value) @value = value end
      #
      #     def fmap(&fn)
      #       new_value = fn.call(value)
      #       new_value ? Some.new(new_value) : None(value)
      #     end
      #   end
      #
      #   class None
      #     include SomePatternMatch.mixin
      #
      #     attr_reader :value
      #
      #     def initialize(value) @value = value end
      #     def fmap(&fn) None.new(value) end
      #   end
      #
      #   Some.new(1)
      #     .fmap { |v| v * 2 }
      #     .match { |m|
      #       m.some { |v| v + 100 }
      #       m.none { "OHNO!" }
      #     }
      #   => 102
      #
      #   Some.new(1)
      #     .fmap { |v| nil }
      #     .match { |m|
      #       m.some { |v| v + 100 }
      #       m.none { "OHNO!" }
      #     }
      #   => "OHNO!"
      #   ```
      #
      # @param destructure: false [Boolean]
      #   Whether or not to destructure values before yielding to a block
      #
      # @param exhaustive: false [Boolean]
      #   If no matches are found, this will raise a
      #   `Qo::Errors::ExhaustiveMatchNotMet` error.
      #
      # @param as: :match [Symbol]
      #   Name to use as a method name bound to the including class
      #
      # @return [Module]
      #   Module to be mixed into a class
      def self.mixin(destructure: false, exhaustive: false, as: :match)
        create_self = -> &function {
          new(destructure: destructure, exhaustive: exhaustive, &function)
        }

        Module.new do
          define_method(as) do |&function|
            create_self.call(&function).call(self)
          end
        end
      end

      # Whether or not the current pattern match requires a matching branch
      #
      # @return [Boolean]
      def exhaustive?
        @exhaustive
      end

      # Whether or not the current pattern match is exhaustive and has a missing
      # default branch
      #
      # @return [Boolean]
      def exhaustive_no_default?
        exhaustive? && !@default
      end

      # Names of all of the available branch names set in `Branching` on
      # registration of a branch
      #
      # @return [Array[String]]
      def available_branch_names
        self.class.available_branches.keys
      end

      # Whether or not all branch types have been provided to the matcher.
      #
      # @return [Boolean]
      def all_branches_provided?
        available_branch_names == @provided_matchers.uniq
      end

      # Whether the current matcher is lacking branches
      #
      # @return [Boolean]
      def lacking_branches?
        exhaustive_no_default? && !all_branches_provided?
      end

      # Calls the pattern matcher, yielding the target value to the first
      # matching branch it encounters.
      #
      # In the case of an exhaustive match, this will raise an error if no
      # default branch is provided.
      #
      # @param value [Any]
      #   Value to match against
      #
      # @return [Any]
      #   Result of the called branch
      #
      # @raises [Qo::Exceptions::ExhaustiveMatchNotMet]
      #   If the matcher is exhaustive and no default branch is provided, it is
      #   considered to have failed an optimistic exhaustive match.
      #
      # @return [nil]
      #   Returns nil if no branch is matched
      def call(value)
        @matchers.each do |matcher|
          status, return_value = matcher.call(value)
          return return_value if status
        end

        raise Qo::Exceptions::ExhaustiveMatchNotMet if exhaustive_no_default?

        if @default
          _, return_value = @default.call(value)
          return_value
        else
          nil
        end
      end

      alias === call
      alias [] call

      # Procified version of `call`
      #
      # @return [Proc[Any] => Any]
      def to_proc
        -> target { self.call(target) }
      end
    end
  end
end
