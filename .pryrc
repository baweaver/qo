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

people_arrays = [
  ['Robert', 22],
  ['Roberta', 22],
  ['Foo', 42],
  ['Bar', 18]
]

people_objects = [
  Person.new('Robert', 22),
  Person.new('Roberta', 22),
  Person.new('Foo', 42),
  Person.new('Bar', 17),
]
