module Qo
  module Branches
    class WhenBranch < Branch
      # The traditional pattern matching branch, based off of `when` from
      # Ruby's `case` statement:
      #
      # ```ruby
      # Qo.case(1) { |m|
      #   m.when(Integer) { |v| v + 2 }
      # }
      # # => 3
      # ```
      #
      # @author baweaver
      # @since 1.0.0
      def initialize(destructure: false)
        super(name: 'when', destructure: destructure, default: false)
      end
    end
  end
end
