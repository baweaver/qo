require "bundler/setup"
require "qo"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

class Person
  attr_reader :name, :age

  def initialize(name, age)
    @name = name
    @age = age
  end

  def adult?
    @age > 17
  end

  def cool?
    @name.include?('Rob')
  end

  def to_h
    {name: @name, age: @age}
  end
end

class Some
  attr_reader :value

  def initialize(value) @value = value end
  def self.[](value)    new(value)     end

  def fmap(&fn)
    new_value = fn.call(value)
    new_value ? Some[new_value] : None[value]
  end
end

class None
  attr_reader :value

  def initialize(value) @value = value end
  def self.[](value)    new(value)     end

  def fmap(&fn) None[value] end
end
