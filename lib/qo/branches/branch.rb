module Qo
  module Branches
    # ### Branches
    #
    # A branch is a particular branch of a pattern match. The default branches
    # emulate a `case` statement. Consider a `case` statement like this:
    #
    # ```ruby
    # case value
    # when condition then first_return
    # else second_return
    # end
    # ```
    #
    # With a Qo branch you would see something like this:
    #
    # ```ruby
    # Qo.match { |m|
    #   m.when(condition) { first_return }
    #   m.else { second_return }
    # }
    # ```
    #
    # The `when` and `else` are the names the branch was "registered" with in
    # `Qo::PatternMatchers::Branching`. The name becomes the method name that
    # the associated matcher uses.
    #
    # ### Order of Execution
    #
    # A branch will execute in the following order:
    #
    # ```
    # value -> precondition ? -> extractor -> condition ? -> destructurer
    # ```
    #
    # Preconditions allow for things like type checks or any static condition
    # that will remain constant across all matches. Think of them as abstracting
    # a single condition to guard before the branch continues.
    #
    # Conditions are typical Qo matchers, as documented in the README. Upon a
    # match, the branch will be considered matched and continue on to calling
    # the associated block function.
    #
    # Extractors are used to pull a value out of a container type, such as
    # `value` for monadic types or `last` for response array tuples.
    #
    # Lastly, if given, Destructurers will destructure an object. That means
    # that the associated function now places great significance on the
    # names of the arguments as they'll be used to extract values from the
    # object that would have normally been returned.
    #
    # Destructuring can be a complicated topic, see the following article to
    # find out more on how this works or see the README for examples:
    #
    # https://medium.com/rubyinside/destructuring-in-ruby-9e9bd2be0360
    #
    # ### Match Tuples
    #
    # Branches will respond with a tuple of (status, value). A status of false
    # indicates a non-match, and a status or true indicates a match. This is done
    # to ensure that truly `false` or `nil` returns are not swallowed by a
    # match.
    #
    # A Pattern Match will use these statuses to find the first matching branch.
    #
    # @author baweaver
    # @since 1.0.0
    class Branch
      # Representation of an unmatched value. These values are wrapped in array
      # tuples to preserve legitimate `false` and `nil` values by indicating
      # the status of the match in the first position and the returned value in
      # the second.
      UNMATCHED = [false, nil]

      # Name of the branch, see the initializer for more information
      attr_reader :name

      # Creates an instance of a Branch
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
      # @return [Qo::Branches::Branch]
      def initialize(name:, precondition: Any, extractor: IDENTITY, destructure: false, default: false)
        @name         = name
        @precondition = precondition.is_a?(Symbol) ? precondition.to_proc : precondition
        @extractor    = extractor.is_a?(Symbol)    ? extractor.to_proc    : extractor
        @destructure  = destructure
        @default      = default
      end

      # A dynamic creator for new branch types to be made on the fly in programs.
      # This exists to make new types of pattern matches to suit your own needs.
      #
      # Prefer the public API to using this method directly, `Qo.create_branch`,
      # mostly because it's less typing.
      #
      # @see `.initialize` for parameter documentation
      #
      # @return [Class]
      #   new Class to be bound to a constant name, or used anonymously
      def self.create(name:, precondition: Any, extractor: IDENTITY, destructure: false, default: false)
        attributes = {
          name:         name,
          precondition: precondition,
          extractor:    extractor,
          destructure:  destructure,
          default:      default
        }

        Class.new(Qo::Branches::Branch) do
          define_method(:initialize) { super(**attributes) }
        end
      end

      # Whether or not this is a default branch
      #
      # @return [Boolean]
      def default?
        @default
      end

      # Uses the current configuration of the branch to create a matcher to
      # be used in a pattern match. The returned proc can be passed a value
      # that will return back a tuple of `(status, value)` to indicate whether
      # or not a match was made with this branch.
      #
      # @param conditions [#===]
      #   A set of conditions to run against, typically a `Qo.and` matcher but
      #   could be anything that happens to respond to `===`.
      #
      # @param destructure: false [Boolean]
      #   Whether or not to run the extracted value through a destructure before
      #   yielding it to the associated block.
      #
      # @param &function [Proc]
      #   Function to be called if a matcher matches.
      #
      # @return [Proc[Any]] [description]
      def create_matcher(conditions, destructure: @destructure, &function)
        function ||= IDENTITY

        destructurer = Destructurers::Destructurer.new(
          destructure: destructure, &function
        )

        Proc.new { |value|
          # If it's a default branch, return true, as conditions are redundant
          if @default
            extracted_value = @extractor.call(value)
            next [true, destructurer.call(extracted_value)]
          end

          if @precondition === value && conditions === (extracted_value = @extractor.call(value))
            [true, destructurer.call(extracted_value)]
          else
            UNMATCHED
          end
        }
      end
    end
  end
end
