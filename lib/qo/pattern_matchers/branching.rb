module Qo
  module PatternMatchers
    module Branching
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def register_branch(branch)
          define_method(branch.name) do |*conditions, **keyword_conditions, &function|
            qo_matcher = Qo::Matchers::Matcher.new(
              'and',
              conditions,
              keyword_conditions
            )

            branch_matcher = branch.create_matcher(
              qo_matcher,
              should_deconstruct: @deconstruct,
              &function
            )

            if branch.default?
              @default = branch_matcher
            else
              @matchers << branch_matcher
            end
          end
        end
      end
    end
  end
end
