require 'qo/exceptions'

module Qo
  module Matchers
    # Creates a PatternMatch, which will evaluate once given a match target.
    #
    # Each GuardBlockMatcher given will be run in sequence until a "match" is
    # located. Once that condition is met, it will call the associated block
    # function of that GuardBlockMatcher with the match target.
    #
    # This is done as an effort to emulate Right Hand Assignment seen in other
    # functionally oriented languages pattern matching systems. Most notably this
    # is done in Scala: (https://docs.scala-lang.org/tour/pattern-matching.html)
    #
    # ```scala
    # notification match {
    #   case Email(email, title, _) =>
    #     s"You got an email from $email with title: $title"
    #
    #   case SMS(number, message) =>
    #     s"You got an SMS from $number! Message: $message"
    #
    #   case VoiceRecording(name, link) =>
    #     s"You received a Voice Recording from $name! Click the link to hear it: $link"
    #
    #   case other => other
    # }
    # ```
    #
    # Qo will instead pipe the entire matched object, and might look something like this:
    #
    # ```ruby
    # # Assuming notification is in the form of a tuple
    #
    # Qo.match(notification,
    #   Qo.m(EMAIL_REGEX, String, :*) { |email, title, _|
    #     "You got an email from #{email} with title: #{title}"
    #   },
    #
    #   Qo.m(PHONE_REGEX, String) { |number, message, _|
    #     "You got an SMS from #{number}! Message: #{message}"
    #   },
    #
    #   Qo.m(String, LINK_REGEX) { |name, link, _|
    #     "You received a Voice Recording from #{name}! Click the link to hear it: #{link}"
    #   },
    #
    #   Qo.m(:*)
    # )
    # ```
    #
    # Efforts to emulate the case class mechanic may be present in later versions,
    # but for now the associated performance penalty may be too steep to consider.
    #
    # We'll evaluate those options in a few experiments later.
    #
    # @author baweaver
    # @since 0.2.0
    #
    class PatternMatch
      def initialize(*matchers)
        raise Qo::Exceptions::NotAllGuardMatchersProvided unless matchers.all? { |q|
          q.is_a?(Qo::Matchers::GuardBlockMatcher)
        }

        @matchers = matchers
      end

      # Function return of a PatternMatch waiting for a target to run
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
      # @return [Any | nil] Result of the piped block, or nil on a miss
      def call(target)
        @matchers.each { |guard_block_matcher|
          did_match, match_result = guard_block_matcher.call(target)
          return match_result if did_match
        }

        nil
      end
    end
  end
end
