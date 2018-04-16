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
def run_benchmark(title, **benchmarks)
  puts '', title, '=' * title.size, ''

  Benchmark.ips do |bm|
    benchmarks.each do |benchmark_name, benchmark_fn|
      bm.report(benchmark_name, &benchmark_fn)
    end

    bm.compare!
  end
end

# Note that the current development of Qo is NOT to be performance first, it's to
# be readability first with performance coming later. That means that early iterations
# may well be slower, but the net expressiveness we get is worth it in the short run.
task :perf do
  # Compare simple array equality. I almost think this isn't fair to Qo considering
  # no sane dev should use it for literal 1 to 1 matches like this.

  simple_array = [1, 1]
  run_benchmark('Array * Array - Literal',
    'Vanilla': -> {
      simple_array == simple_array
    },

    'Qo.and':  -> {
      Qo.and(*simple_array).call(simple_array)
    }
  )

  # Compare testing indexed array matches. This gets a bit more into what Qo does,
  # though I feel like there are optimizations that could be had here as well.

  range_match_set    = [1..10, 1..10, 1..10, 1..10]
  range_match_target = [1, 2, 3, 4]

  run_benchmark('Array * Array - Index pattern match',
    'Vanilla': -> {
      range_match_target.each_with_index.all? { |x, i| range_match_set[i] === x }
    },

    'Qo.and':  -> {
      Qo.and(*range_match_set).call(range_match_target)
    }
  )

  # Now we're getting into things Qo makes sense for. Comparing an entire list
  # against a stream of predicates to check

  numbers_array = [1, 2.0, 3, 4]

  run_benchmark('Array * Object - Predicate match',
    'Vanilla': -> {
      numbers_array.all? { |i| i.is_a?(Integer) && i.even? && (20..30).include?(i) }
    },

    'Qo.and':  -> {
      numbers_array.all?(&Qo.and(Integer, :even?, 20..30))
    }
  )

  # This one is a bit interesting. The vanilla version is written to reflect that
  # it has NO idea what the length of either set is, which is exactly what Qo
  # has to deal with as well.

  people_array_target = [
    ['Robert', 22],
    ['Roberta', 22],
    ['Foo', 42],
    ['Bar', 18]
  ]

  people_array_query = [/Rob/, 15..25]

  run_benchmark('Array * Array - Select index pattern match',
    'Vanilla': -> {
      people_array_target.select { |person|
        person.each_with_index.all? { |a, i| people_array_query[i] === a }
      }
    },

    'Qo.and':  -> {
      Qo.and(*people_array_query).call(people_array_target)
    }
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
  # run_benchmark('Empty on blank array',
  #   'empty?':     -> { [].empty?     },
  #   'size == 0':  -> { [].size == 0  },
  #   'size.zero?': -> { [].size.zero? },
  # )

  array = (1..1000).to_a
  # run_benchmark('Empty on several elements array',
  #   'empty?':     -> { array.empty?     },
  #   'size == 0':  -> { array.size == 0  },
  #   'size.zero?': -> { array.size.zero? },
  # )

  hash = array.map { |v| [v, v] }.to_h

  run_benchmark('Empty on blank hash vs array',
    'hash empty?':  -> { {}.empty? },
    'array empty?': -> { [].empty? },

    'full hash empty?':  -> { hash.empty? },
    'full array empty?': -> { array.empty? },
  )
end
