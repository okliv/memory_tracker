module MemoryTracker
  class Request
    include Sys if RUBY_PLATFORM.include?('linux')

    attr_reader :start_gcstat, :end_gcstat
    attr_reader :gcstat_delta
    attr_reader :rss, :vsize

    extend Forwardable
    def_delegators :@env, :path, :controller, :action

    def initialize(env)
      @env          = env
      @start_gcstat = GcStat.new(self.class.rss, self.class.vsize)
    end

    def close
      @end_gcstat   = GcStat.new(self.class.rss, self.class.vsize)
      @gcstat_delta = GcStatDelta.new(@start_gcstat, @end_gcstat)
      self
    end

    private

    def self.ps_data_provider
      RUBY_PLATFORM.include?('darwin') ? PS.pid(Process.pid) : ProcTable.ps(Process.pid)
    end

    def self.ps_data
      [*ps_data_provider].first
    end

    def self.rss
      ps_data.rss / 1024 #* 0.004096
    end

    def self.vsize
      ps_data.vsize / 1024
    end

    # def self.rss
    #   rss = ProcTable.ps(Process.pid).rss * 0.004096
    # end
    #
    # def self.vsize
    #   vsize = ProcTable.ps(Process.pid).vsize * 0.000001
    # end


  end
end
