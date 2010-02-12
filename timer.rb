# Simple timer for benchmarks
def tm()
  start = Time.now
  result = yield
  delta = Time.now - start
  puts "Elapsed: #{delta} seconds"
  result
end
