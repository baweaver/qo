module Qo
  module Evil
    class Matcher
      def initialize(type, *array_matchers, **keyword_matchers)
        @type             = type
        @array_matchers   = array_matchers
        @keyword_matchers = keyword_matchers
      end

      def to_proc
        Proc.new { |target| self.call(target) }
      end

      def call(target)
        return @_proc.call(target) if @_proc

        bind = binding

        compiled_matchers, variables = compile(target)
        match_query = merge_compilation(compiled_matchers)

        variables.each { |name, var| bind.local_variable_set(name.to_sym, var) }

        puts match_query

        puts(
          "compiled_matchers:    #{compiled_matchers}",
          "variables:            #{variables}",
          "match_query:          #{match_query}",
          "target:               #{target}",
          "bind.local_variables: #{bind.local_variables}",
        )

        @_proc = bind.eval(%~
          Proc.new { |target| #{match_query} }
        ~)

        @_proc.call(target)
      end

      def compile(target)
        variables = {}

        matchers = if @array_matchers.empty?
          if target.is_a?(Hash)
            raise 'hell'
            @keyword_matchers.map { |key, m|

            }
          else
            raise 'hell'
            @keyword_matchers.map { |key, m|

            }
          end
        else
          if target.is_a?(Array)
            # puts "Array matches Array"

            @array_matchers.each_with_index.map { |m, i|
              v = array_array_mapping(m, i)

              # puts(
              #   "m: #{m}",
              #   "i: #{i}",
              #   "v: #{v}",
              # )

              next v if v

              name = "_qo_evil_#{var_names.next}"
              variables[name] = m
              "#{name} === target[#{i}]"
            }
          else
            @array_matchers.map { |m|
              v = array_object_mapping(m) and next v if v
              name = "_qo_evil_#{var_names.next}"
              variables[name] = m
              "#{name} === target"
            }
          end
        end

        [matchers, variables]
      end

      def merge_compilation(compiled_matchers)
        return compiled_matchers.join(' && ') if @type == 'and'
        return compiled_matchers.join(' || ') if @type == 'or'

        "!(#{compiled_matchers.join(' || ')})" # not
      end

      def var_names
        @_var_names ||= ('a'..'zzz').to_enum
      end

      def array_object_mapping(matcher)
        case matcher
        when :*
          "true"
        when Class
          "target.is_a?(#{matcher})"
        when Integer, Float, TrueClass, FalseClass, NilClass
          "#{matcher} == target"
        when String
          "'#{sanitize(matcher)}' == target"
        when Symbol
          "target.#{sanitize(matcher)}"
        when Regexp
          "#{matcher.inspect}.match?(target)"
        when Range
          "(#{matcher}).include?(target)"
        else
          false
        end
      end

      def array_array_mapping(matcher, i)
        case matcher
        when :*
          "true"
        when Class
          "target[#{i}].is_a?(#{matcher})"
        when Integer, Float, TrueClass, FalseClass, NilClass
          "#{matcher} == target[#{i}]"
        when String
          "'#{sanitize(matcher)}' == target[#{i}]"
        when Symbol
          "target[#{i}].#{sanitize(matcher)}"
        when Regexp
          "#{matcher.inspect}.match?(target[#{i}])"
        when Range
          "(#{matcher.inspect}).include?(target[#{i}])"
        else
          false
        end
      end

      def sanitize(str)
        str.to_s.gsub(/[^a-zA-Z0-9_]/, '')
      end
    end
  end
end
