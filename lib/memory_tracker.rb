require 'memory_tracker/engine' if defined?(Rails)
require 'memory_tracker/memory_tracker'
if RUBY_PLATFORM.include?('darwin')
  require 'ps'
else
  require 'sys/proctable'
end
