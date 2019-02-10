module Qo
  module PatternMatchers
    DEFAULT_BRANCHES = [ Qo::Branches::WhenBranch.new, Qo::Branches::ElseBranch.new ]

    class PatternMatch
      def initialize(branches: DEFAULT_BRANCHES, deconstruct: false, &fn)
        @branches = branches
        @matchers = []
        @default  = nil

        # Enable later
        # raise Qo::MultipleDefaultBranches unless brances.one?(&:default?)
        # raise Qo::BranchNameCollision unless branches.uniq_by(&:name).size == branches.size

        branches.each do |branch|
          branch.deconstruct = deconstruct
          register_branch(branch)
        end

        yield(self)
      end

      def construct(&fn)
        yield(self)
      end

      def call(value)
        @matchers.each do |matcher|
          status, return_value = matcher.call(value)
          return return_value if status
        end

        if @default
          _, return_value = @default.call(value)
          return_value
        else
          nil
        end
      end

      alias === call
      alias [] call

      def to_proc
        -> target { self.call(target) }
      end

      private def register_branch(branch)
        define_singleton_method(branch.name) do |*conditions, **keyword_conditions, &function|
          matcher = branch.create_matcher(Qo.and(*conditions, **keyword_conditions), &function)

          if branch.default?
            @default = matcher
          else
            @matchers << matcher
          end
        end
      end
    end
  end
end
