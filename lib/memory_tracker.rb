require 'memory_tracker/engine' if defined?(Rails)
require 'memory_tracker/memory_tracker'
require 'ps' if RUBY_PLATFORM.include?('darwin')
require 'sys/proctable' if RUBY_PLATFORM.include?('linux')
