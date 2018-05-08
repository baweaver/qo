require 'qo/exceptions'

module Qo
  module Evil
    class PatternMatch
      attr_reader :full_query

      def initialize(*matchers)
        raise Qo::Exceptions::NotAllGuardMatchersProvided unless matchers.all? { |q|
          q.is_a?(Qo::Evil::GuardBlockMatcher)
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

      def var_names
        @_var_names ||= ('a'..'zzz').to_enum
      end

      def call(target)
        variables = {}

        @full_query = @matchers.each_with_index.map { |m, i|
          query = m.pre_render(target)
          var_name = "_qo_evil_guard_fn_#{var_names.next}"

          variables[var_name] = m.fn

          "return #{var_name}.call(target) if (#{query})"
        }.join("\n")

        # puts @full_query

        bind = binding

        variables.each { |name, var| bind.local_variable_set(name.to_sym, var) }

        @_proc = bind.eval(%~
          Proc.new { |target|
            #{@full_query}
          }
        ~)

        self.define_singleton_method(:call, @_proc)
        self.define_singleton_method(:to_proc, proc { @_proc })

        @_proc.call(target)

        @matchers.each { |guard_block_matcher|
          did_match, match_result = guard_block_matcher.render(target)
          return match_result if did_match
        }

        nil
      end
    end
  end
end
