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
require 'qo/matchers/pattern_match_block'

# Helpers
require 'qo/helpers'

# Public API
require 'qo/exceptions'
require 'qo/public_api'

module Qo
  extend Qo::Exceptions
  extend Qo::Helpers
  extend Qo::PublicApi
end
