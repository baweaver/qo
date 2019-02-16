module Qo
  module Branches
    # A default branch to for when other conditions fail.
    #
    # ```ruby
    # Qo.case(1) { |m|
    #   m.else { |v| v + 2 }
    # }
    # # => 3
    # ```
    #
    # @author baweaver
    # @since 1.0.0
    class ElseBranch < Branch
      def initialize(destructure: false)
        super(name: 'else', destructure: destructure, default: true)
      end
    end
  end
end
