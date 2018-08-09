# Wildcard matching
require 'any'

require "qo/version"

# Matchers
require 'qo/matchers/base_matcher'
require 'qo/matchers/array_matcher'
require 'qo/matchers/hash_matcher'
require 'qo/matchers/guard_block_matcher'

# Meta Matchers
require 'qo/matchers/pattern_match'

# Helpers
require 'qo/helpers'

# Public API
require 'qo/api/exceptions'
require 'qo/api/public'

module Qo
  # Identity function that returns its argument directly
  IDENTITY = -> v { v }

  extend Qo::Api::Exceptions
  extend Qo::Api::Helpers
  extend Qo::Api::PublicApi
end
