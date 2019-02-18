module Qo
  module PatternMatchers
    # A module to allow the registration of braches to a pattern matcher.
    #
    # @author baweaver
    # @since 1.0.0
    #
    module Branching
      # On inclusion, extend the class including this module with branch
      # registration methods.
      #
      # @param base [Class]
      #   Class including this module, passed from `include`
      def self.included(base)
        base.extend(ClassMethods)
      end

      # Class methods to extend the including class with
      #
      # @author baweaver
      # @since 1.0.0
      module ClassMethods
        attr_reader :available_branches

        # Registers a branch to a pattern matcher.
        #
        # This defines a method on the pattern matcher matching the `name` of
        # the branch. If the name is `where`, the pattern matcher will now be
        # given a method called `where` with which to match with.
        #
        # When called, this will either ammend a matcher to the list of matchers
        # or set a default matcher if the branch happens to be a default.
        #
        # It also adds the branch to a registry of branches for later use in
        # error handling or other such potential requirements.
        #
        # @param branch [Branch]
        #   Branch object to register with a pattern matcher
        def register_branch(branch)
          @available_branches ||= {}
          @available_branches[branch.name] = branch

          define_method(branch.name) do |*conditions, **keyword_conditions, &function|
            @provided_matchers ||= []
            @provided_matchers.push(branch.name)

            qo_matcher = Qo::Matchers::Matcher.new('and', conditions, keyword_conditions)

            branch_matcher = branch.create_matcher(
              qo_matcher, destructure: @destructure, &function
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
