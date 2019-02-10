# Wildcard matching
require 'any'

require "qo/version"

# Helpers
require 'qo/helpers'

# Public API
require 'qo/exceptions'
require 'qo/public_api'

module Qo
  # Identity function that returns its argument directly
  IDENTITY = -> v { v }

  extend Qo::Exceptions
  extend Qo::Helpers
  extend Qo::PublicApi
end

# Matchers
require 'qo/matchers/matcher'

# Branches
require 'qo/branches/branches'

# Pattern Matchers
require 'qo/pattern_matchers/pattern_matchers'
