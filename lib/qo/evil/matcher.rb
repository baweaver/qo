module Qo
  module Evil
    class Matcher
      attr_reader :query

      def initialize(type, *array_matchers, **keyword_matchers)
        @type             = type.tap { |v| p "type: #{v}" if @debug }
        @array_matchers   = array_matchers.tap { |v| p "array_matchers: #{v}" if @debug }
        @keyword_matchers = keyword_matchers.tap { |v| p "keyword_matchers: #{v}" if @debug }
        @debug = false
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

        puts match_query if @debug

        puts(
          # "compiled_matchers:    #{compiled_matchers}",
          "variables:            #{variables}",
          "match_query:          #{match_query}",
          "target:               #{target}",
          "bind.local_variables: #{bind.local_variables}",
        ) if @debug

        # p "Qo::Evil generated: Proc.new { |target| #{match_query} }"

        @query = match_query

        @_proc = bind.eval(%~
          Proc.new { |target| #{match_query} }
        ~)

        self.define_singleton_method(:call, @_proc)
        self.define_singleton_method(:to_proc, proc { @_proc })

        @_proc.call(target)
      end

      def compile(target)
        variables = {}

        matchers = if @array_matchers.empty?
          if target.is_a?(Hash)
            @keyword_matchers.map { |key, m|
              v = hash_hash_mapping(m, key)

              puts(
                "m:   #{m}",
                "key: #{key}",
                "v:   #{v}",
              ) if @debug

              next v if v

              name = "_qo_evil_#{var_names.next}"
              variables[name] = m
              typed_key = key.is_a?(Symbol) ? ":#{key}" : "'#{key}'"
              "#{name} === target[#{typed_key}]"
            }
          else
            @keyword_matchers.map { |key, m|
              v = hash_object_mapping(m, key)

              puts(
                "m:   #{m}",
                "key: #{key}",
                "v:   #{v}",
              ) if @debug

              next v if v

              name = "_qo_evil_#{var_names.next}"
              variables[name] = m
              "#{name} === target.#{sanitize(key)}"
            }
          end
        else
          if target.is_a?(Array)
            @array_matchers.each_with_index.map { |m, i|
              v = array_array_mapping(m, i, target)

              puts(
                "m: #{m}",
                "i: #{i}",
                "v: #{v}",
              ) if @debug

              next v if v

              name = "_qo_evil_#{var_names.next}"
              variables[name] = m
              "#{name} === target[#{i}]"
            }
          else
            @array_matchers.map { |m|
              v = array_object_mapping(m)

              puts(
                "m: #{m}",
                "v: #{v}",
              ) if @debug

              next v if v

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

      def array_array_mapping(matcher, i, target)
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
          if target[i].respond_to?(matcher)
            "target[#{i}].#{sanitize(matcher)}"
          else
            ":#{sanitize(matcher)} == target[#{i}]"
          end
        when Regexp
          "#{matcher.inspect}.match?(target[#{i}])"
        when Range
          "(#{matcher.inspect}).include?(target[#{i}])"
        else
          false
        end
      end

      def hash_hash_mapping(matcher, key)
        typed_key = key.is_a?(Symbol) ? ":#{key}" : "'#{key}'"
        case matcher
        when :*
          "true"
        when Class
          "target[#{typed_key}].is_a?(#{matcher})"
        when Integer, Float, TrueClass, FalseClass, NilClass
          "#{matcher} == target[#{typed_key}]"
        when String
          "'#{sanitize(matcher)}' == target[#{typed_key}]"
        when Symbol
          "target[#{typed_key}].#{sanitize(matcher)}"
        when Regexp
          "#{matcher.inspect}.match?(target[#{typed_key}])"
        when Range
          "(#{matcher.inspect}).include?(target[#{typed_key}])"
        else
          false
        end
      end

      def hash_object_mapping(matcher, key)
        clean_key = sanitize(key).to_sym

        case matcher
        when :*
          "true"
        when Class
          "target.#{clean_key}.is_a?(#{matcher})"
        when Integer, Float, TrueClass, FalseClass, NilClass
          "#{matcher} == target.#{clean_key}"
        when String
          "'#{sanitize(matcher)}' == target.#{clean_key}"
        when Symbol
          "target.#{clean_key}.#{sanitize(matcher)}"
        when Regexp
          "#{matcher.inspect}.match?(target.#{clean_key})"
        when Range
          "(#{matcher.inspect}).include?(target.#{clean_key})"
        else
          false
        end
      end

      def sanitize(str)
        str.to_s.gsub(/[^a-zA-Z0-9_?!]/, '')
      end
    end
  end
end
