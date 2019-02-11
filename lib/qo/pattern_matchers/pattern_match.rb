module Qo
  module PatternMatchers
    class PatternMatch
      include Branching

      register_branch Qo::Branches::WhenBranch.new
      register_branch Qo::Branches::ElseBranch.new

      def initialize(destructure: false, &fn)
        @matchers    = []
        @default     = nil
        @destructure = destructure

        yield(self)
      end

      def self.create(branches: [])
        Class.new(Qo::PatternMatchers::PatternMatch) do
          branches.each { |branch| register_branch(branch.new) }
        end
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
    end
  end
end
