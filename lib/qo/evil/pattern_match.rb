require 'qo/exceptions'

module Qo
  module Evil
    class PatternMatch
      attr_reader :full_query

      def initialize(matchers)
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

      def call(target)
        @full_query = @matchers.each_with_index.map { |m, i|
          query = m.pre_render(target)
          function_name = "_qo_evil_guard_fn_#{i}"

          self.define_singleton_method(function_name, &m.fn)

          fn_arity = m.fn.arity

          args = case fn_arity
          when 0 then ''
          when 1 then 'target'
          else fn_arity.times.map { |n| "target[#{n}]" }.join(', ')
          end

          "return #{function_name}(#{args}) if (#{query})"
        }.join("\n")

        @_proc = binding.eval("lambda { |target| #{@full_query} }")

        self.define_singleton_method(:call, @_proc)
        self.define_singleton_method(:to_proc, -> { @_proc })

        @_proc.call(target)
      end
    end
  end
end
