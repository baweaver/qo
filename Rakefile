require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'benchmark/ips'
require 'qo'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

# Run a benchmark given a title and a set of benchmarks. Admittedly this
# is done because the Benchmark.ips code can get a tinge repetitive and this
# is easier to write out.
#
# @param title [String] Title of the benchmark
# @param **benchmarks [Hash[Symbol, Proc]] Name to Proc to run to benchmark it
#
# @note Notice I'm using `'String': -> {}` instead of hashrockets? Kwargs doesn't
#       take string / hashrocket arguments, probably to prevent abuse of the
#       "anything can be a key" bit of Ruby.
#
# @return [Unit] StdOut
def run_benchmark(title, quiet = false, **benchmarks)
  puts '', title, '=' * title.size, ''

  # Validation
  benchmarks.each do |benchmark_name, benchmark_fn|
    puts "#{benchmark_name} result: #{benchmark_fn.call()}"
  end unless quiet

  puts

  Benchmark.ips do |bm|
    benchmarks.each do |benchmark_name, benchmark_fn|
      bm.report(benchmark_name, &benchmark_fn)
    end

    bm.compare!
  end
end

def xrun_benchmark(title, **benchmarks) end

# Note that the current development of Qo is NOT to be performance first, it's to
# be readability first with performance coming later. That means that early iterations
# may well be slower, but the net expressiveness we get is worth it in the short run.
task :perf do
  puts "Running on Qo v#{Qo::VERSION} at commit #{`git rev-parse HEAD`}"
  puts RUBY_VERSION

  # Compare simple array equality. I almost think this isn't fair to Qo considering
  # no sane dev should use it for literal 1 to 1 matches like this.

  simple_array = [1, 1]

  simple_qo = Qo.and(1, 1)
  simple_qo_evil = Qo::Evil.and(1, 1)

  run_benchmark('Array * Array - Literal',
    'Vanilla Optimized': -> {
      simple_array == simple_array
    },

    'Qo.and':  -> {
      simple_qo.call(simple_array)
    },

    'Qo EVIL': -> {
      simple_qo_evil.call(simple_array)
    }
  )

  # Compare testing indexed array matches. This gets a bit more into what Qo does,
  # though I feel like there are optimizations that could be had here as well.

  range_match_set    = [1..10, 1..10, 1..10, 1..10]
  range_match_target = [1, 2, 3, 4]

  range_qo = Qo.and(1..10, 1..10, 1..10, 1..10)
  range_qo_evil = Qo::Evil.and(1..10, 1..10, 1..10, 1..10)

  run_benchmark('Array * Array - Index pattern match',
    'Vanilla': -> {
      range_match_target.each_with_index.all? { |x, i| range_match_set[i] === x }
    },

    'Vanilla Optimized': -> {
      range_match_set[0] === range_match_target[0] &&
      range_match_set[1] === range_match_target[1] &&
      range_match_set[2] === range_match_target[2] &&
      range_match_set[3] === range_match_target[3]
    },

    'Qo.and':  -> {
      range_qo.call(range_match_target)
    },

    'Qo EVIL':  -> {
      range_qo_evil.call(range_match_target)
    },
  )

  # Now we're getting into things Qo makes sense for. Comparing an entire list
  # against a stream of predicates to check

  numbers_array = [1, 2.0, 3, 4]

  ao_p_v       = proc { |i| i.is_a?(Integer) && i.even? && (20..30).include?(i) }
  ao_p_qo      = Qo.and(Integer, :even?, 20..30)
  ao_p_qo_evil = Qo::Evil.and(Integer, :even?, 20..30)

  run_benchmark('Array * Object - Predicate match',
    'Vanilla': -> {
      numbers_array.all?(&ao_p_v)
    },

    'Qo.and':  -> {
      numbers_array.all?(&ao_p_qo)
    },

    'Qo EVIL':  -> {
      numbers_array.all?(&ao_p_qo_evil)
    },
  )

  # This one is a bit interesting. The vanilla version is written to reflect that
  # it has NO idea what the length of either set is, which is exactly what Qo
  # has to deal with as well.

  people_array_target = [
    ['Robert', 22],
    ['Roberta', 22],
    ['Foo', 42],
    ['Bar', 18]
  ] * 1_000

  people_array_query = [/Rob/, 15..25]

  qo_and      = Qo.and(/Rob/, 15..25)
  qo_evil_and = Qo::Evil.and(/Rob/, 15..25)
  normal_proc = proc { |person|
    person.each_with_index.all? { |a, i| people_array_query[i] === a }
  }
  normal_cheating_proc = proc { |person|
    /Rob/.match?(person[0]) && (15..25).include?(person[1])
  }

  puts(
    "Array size:        #{people_array_target.size}",
    "Qo.and == Qo EVIL: #{people_array_target.select(&qo_and) == people_array_target.select(&qo_evil_and)}",
    "Qo EVIL == Normal: #{people_array_target.select(&qo_evil_and) == people_array_target.select(&normal_proc)}",
  )

  run_benchmark('Array * Array - Select index pattern match', true,
    'Vanilla': -> {
      people_array_target.select(&normal_proc)
    },

    'Vanilla Optimized': -> {
      people_array_target.select(&normal_cheating_proc)
    },

    'Qo.and':  -> {
      people_array_target.select(&qo_and)
    },

    'Qo EVIL':  -> {
      people_array_target.select(&qo_evil_and)
    },
  )

  people_hashes = people_array_target.map { |(name, age)| {name: name, age: age} }

  hash_hash_vanilla = proc { |person| (15..25).include?(person[:age]) && /Rob/.match?(person[:name]) }
  hash_hash_qo      = Qo.and(name: /Rob/, age: 15..25)
  hash_hash_qo_evil = Qo::Evil.and(name: /Rob/, age: 15..25)

  puts(
    "Array size:        #{people_hashes.size}",
    "Qo.and == Qo EVIL: #{people_hashes.select(&hash_hash_qo) == people_hashes.select(&hash_hash_qo_evil)}",
    "Qo EVIL == Normal: #{people_hashes.select(&hash_hash_qo_evil) == people_hashes.select(&hash_hash_vanilla)}",
  )

  run_benchmark('Hash * Hash - Hash intersection', true,
    'Vanilla': -> { people_hashes.select(&hash_hash_vanilla) },
    'Qo.and':  -> { people_hashes.select(&hash_hash_qo) },
    'Qo EVIL':  -> { people_hashes.select(&hash_hash_qo_evil) },
  )

  Person = Struct.new(:name, :age)
  people = [
    Person.new('Robert', 22),
    Person.new('Roberta', 22),
    Person.new('Foo', 42),
    Person.new('Bar', 17)
  ] * 1_000

  hash_object_vanilla = proc { |person| (15..25).include?(person.age) && /Rob/.match?(person.name) }
  hash_object_qo      = Qo.and(name: /Rob/, age: 15..25)
  hash_object_qo_evil = Qo::Evil.and(name: /Rob/, age: 15..25)

  puts(
    "Array size:        #{people.size}",
    "Qo.and == Qo EVIL: #{people.select(&hash_object_qo) == people.select(&hash_object_qo_evil)}",
    "Qo EVIL == Normal: #{people.select(&hash_object_qo_evil) == people.select(&hash_object_vanilla)}",
  )

  run_benchmark('Hash * Object - Property match', true,
    'Vanilla': -> { people.select(&hash_object_vanilla) },
    'Qo.and':  -> { people.select(&hash_object_qo) },
    'Qo EVIL': -> { people.select(&hash_object_qo_evil) },
  )
end

task :perf_pattern_match do
  require 'dry-matcher'
  # require 'pattern-match'
  # using PatternMatch

  # Match `[:ok, some_value]` for success
  success_case = Dry::Matcher::Case.new(
    match: -> value { value.first == :ok },
    resolve: -> value { value.last }
  )

  # Match `[:err, some_error_code, some_value]` for failure
  failure_case = Dry::Matcher::Case.new(
    match: -> value, *pattern {
      value[0] == :err && (pattern.any? ? pattern.include?(value[1]) : true)
    },
    resolve: -> value { value.last }
  )

  # Build the matcher
  matcher = Dry::Matcher.new(success: success_case, failure: failure_case)

  qo_m = proc { |target|
    Qo.match(target,
      Qo.m(:ok)  { |(s, v)| v },
      Qo.m(:err) { "ERR!" }
    )
  }

  em = Qo::Evil.match(
    Qo::Evil.m(:ok)  { |(s, v)| v },
    Qo::Evil.m(:err) { 'ERR!' }
  )

  qo_e_m = proc { |target| em.call(target) }

  # pm_m = proc { |target|
  #   match(target) do
  #     with(_[:ok, a]) { a }
  #     with(_[:err, a]) { 'ERR!' }
  #   end
  # }

  # eg_m = Qo[:ok, :*]

  dm_m = proc { |target|
    matcher.(target) do |m|
      m.success { |v| v }
      m.failure { 'ERR!' }
    end
  }

  v_m = proc { |target|
    next target[1] if target[0] == :ok
    'ERR!'
  }

  ok_target  = [:ok, 12345]
  err_target = [:err, "OH NO!"]

  run_benchmark('Single Item Tuple',
    'Qo': -> {
      "OK: #{qo_m[ok_target]}, ERR: #{qo_m[err_target]}"
    },

    'Qo Evil': -> {
      "OK: #{qo_e_m[ok_target]}, ERR: #{qo_e_m[err_target]}"
    },

    # 'PatternMatch': -> {
    #   "OK: #{pm_m[ok_target]}, ERR: #{pm_m[err_target]}"
    # },

    'DryRB': -> {
      "OK: #{dm_m[ok_target]}, ERR: #{dm_m[err_target]}"
    },

    'Vanilla': -> {
      "OK: #{v_m[ok_target]}, ERR: #{v_m[err_target]}"
    },
  )

  collection = [ok_target, err_target] * 2_000

  run_benchmark('Large Tuple Collection', true,
    'Qo':           -> { collection.map(&qo_m) },
    'Qo Evil':      -> { collection.map(&qo_e_m) },
    # 'PatternMatch': -> { collection.map(&pm_m) },
    'DryRB':        -> { collection.map(&dm_m) },
    'Vanilla':      -> { collection.map(&v_m) }
  )

  Person = Struct.new(:name, :age)
  people = [
    Person.new('Robert', 22),
    Person.new('Roberta', 22),
    Person.new('Foo', 42),
    Person.new('Bar', 17)
  ] * 1_000

  v_om = proc { |target|
    if /^F/.match?(target.name) && (30..50).include?(target.age)
      "It's foo!"
    else
      "Not foo"
    end
  }

  qo_om = Qo.match(
    Qo.m(name: /^F/, age: 30..50)  { "It's foo!" },
    Qo.m(:*) { "Not foo" }
  )

  qo_e_om = Qo::Evil.match(
    Qo::Evil.m(name: /^F/, age: 30..50)  { "It's foo!" },
    Qo::Evil.m(:*) { "Not foo" }
  )

  run_benchmark('Large Object Collection', true,
    'Qo':           -> { people.map(&qo_om) },
    'Qo Evil':      -> { people.map(&qo_e_om) },
    'Vanilla':      -> { people.map(&v_om) }
  )

end

# Below this mark are mostly my experiments to see what features perform a bit better
# than others, and are mostly left to check different versions of Ruby against eachother.
#
# Feel free to use them in development, but the general consensus of them is that
# `send` type methods are barely slower. One _could_ write an IIFE to get around
# that and maintain the flexibility but it's a net loss of clarity.
#
# Proc wise, they're all within margin of error. We just need to be really careful
# of the 2.4+ bug of lambdas not destructuring automatically, which will wreak
# havoc on hash matchers.

task :kwargs_vs_positional do
  def add_kw(a:, b:, c:, d:) a + b + c + d end

  def add_pos(a,b,c,d) a + b + c + d end

  run_benchmark('Positional vs KW Args',
    'keyword':      -> { add_kw(a: 1, b: 2, c: 3, d: 4) },
    'positional':   -> { add_pos(1,2,3,4) }
  )
end

task :perf_predicates do
  array = (1..1000).to_a

  run_benchmark('Predicates any?',
    'block_any?':      -> { array.any? { |v| v.even? } },
    'proc_any?':       -> { array.any?(&:even?) },
    'send_proc_any?':  -> { array.public_send(:any?, &:even?) }
  )

  run_benchmark('Predicates all?',
    'block_all?':      -> { array.all? { |v| v.even? } },
    'proc_all?':       -> { array.all?(&:even?) },
    'send_proc_all?':  -> { array.public_send(:all?, &:even?) }
  )

  run_benchmark('Predicates none?',
    'block_none?':     -> { array.none? { |v| v.even? } },
    'proc_none?':      -> { array.none?(&:even?) },
    'send_proc_none?': -> { array.public_send(:none?, &:even?) },
  )

  even_stabby_lambda = -> n { n % 2 == 0 }
  even_lambda        = lambda { |n| n % 2 == 0 }
  even_proc_new      = Proc.new { |n|  n % 2 == 0 }
  even_proc_short    = proc { |n|  n % 2 == 0 }
  even_to_proc       = :even?.to_proc

  run_benchmark('Types of Functions in Ruby',
    even_stabby_lambda: -> { array.all?(&even_stabby_lambda) },
    even_lambda:        -> { array.all?(&even_lambda) },
    even_proc_new:      -> { array.all?(&even_proc_new) },
    even_proc_short:    -> { array.all?(&even_proc_short) },
    even_to_proc:       -> { array.all?(&even_to_proc) },
  )
end

task :perf_random do
  run_benchmark('Empty on blank array',
    'empty?':     -> { [].empty?     },
    'size == 0':  -> { [].size == 0  },
    'size.zero?': -> { [].size.zero? },
  )

  array = (1..1000).to_a
  run_benchmark('Empty on several elements array',
    'empty?':     -> { array.empty?     },
    'size == 0':  -> { array.size == 0  },
    'size.zero?': -> { array.size.zero? },
  )

  hash = array.map { |v| [v, v] }.to_h

  run_benchmark('Empty on blank hash vs array',
    'hash empty?':  -> { {}.empty? },
    'array empty?': -> { [].empty? },

    'full hash empty?':  -> { hash.empty? },
    'full array empty?': -> { array.empty? },
  )
end

class CompiledMatch
  def initialize(*matchers)
    @matchers = matchers
  end

  def to_proc
    @_call_method ||= eval(%~
      Proc.new { |target| #{matchers_as_variants} }
    ~)
  end

  def matchers_as_variants
    @_mavs = @matchers.map { |m| variant(m) }.join(' && ')
  end

  def variant(matcher)
    case matcher
    when :*
      "true"
    when Class
      "target.is_a?(#{matcher})"
    when Regexp
      "#{matcher.inspect}.match?(target)"
    when Integer, Float
      "#{matcher} == target"
    when Range
      "(#{matcher}).include?(target)"
    when Symbol
      "target.#{matcher}"
    else
      "#{matcher} === target"
    end
  end

  def call(target)
    self.to_proc.call(target)
  end
end

task :perf_compile do
  comp_match = CompiledMatch.new(Integer, 1..20, :odd?)

  targets = [1, 2, 3] * 1_000

  run_benchmark('Empty on blank array', true,
    'Compiled Match': -> { targets.select(&comp_match) },
    'Vanilla':        -> { targets.select { |v| v.is_a?(Integer) && (1..20).include?(v) && v.odd? } },
    'Qo Match':       -> { targets.select(&Qo[Integer, 1..20, :odd?]) }
  )
end
