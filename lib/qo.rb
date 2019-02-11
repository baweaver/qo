# Wildcard matching
require 'any'

require "qo/version"

# Helpers
require 'qo/helpers'

# Public API
require 'qo/exceptions'
require 'qo/public_api'

module Qo
  # Identity function that returns its argument directly. Argument name is
  # important, as it will extract the literal identity of the object in
  # the case of a non-destructured match, and the object itself in the
  # case of a destructured one.
  IDENTITY = -> itself { itself }

  extend Qo::Exceptions
  extend Qo::Helpers
  extend Qo::PublicApi
end

# Destructurers
require 'qo/destructurers/destructurers'

# Matchers
require 'qo/matchers/matcher'

# Branches
require 'qo/branches/branches'

# Pattern Matchers
require 'qo/pattern_matchers/pattern_matchers'
