module Qo
  # In Qo, a Branch is one of the callable branches in a pattern match. Most
  # commonly you'll see this expressed in a `where` or `else` branch, named
  # as such to emulate a `case` statement:
  #
  # ```ruby
  # Qo.match { |m|
  #   m.when(conditions) { code executed when matched }
  #   m.else { code executed otherwise }
  # }
  # ```
  #
  # More documentation on the creation of branches is available in `Branch`
  #
  # @see Qo::Branches::Branch
  #
  # @author baweaver
  # @since 1.0.0
  module Branches
  end
end

# Base branch type which defines the interface
require 'qo/branches/branch'

# The branches you're probably used to with `where` and `else`
require 'qo/branches/when_branch'
require 'qo/branches/else_branch'

# Result type matchers for tuples like `[:ok, value]`
require 'qo/branches/success_branch'
require 'qo/branches/error_branch'
require 'qo/branches/failure_branch'

# Monadic matchers to extract values from items
require 'qo/branches/monadic_where_branch'
require 'qo/branches/monadic_else_branch'
