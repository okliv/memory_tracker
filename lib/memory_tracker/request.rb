module MemoryTracker
  class Request
    # include Sys

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

    # def self.rss
    #   rss = ProcTable.ps(Process.pid).rss * 0.004096
    # end
    #
    # def self.vsize
    #   vsize = ProcTable.ps(Process.pid).vsize * 0.000001
    # end

    def self.rss
      rss = PS.pid(Process.pid).first.rss / 1024 rescue 0 #* 0.004096
    end

    def self.vsize
      vsize = PS.pid(Process.pid).first.vsize / 1024 rescue 0
    end

  end
end
