require 'spec_helper'

def sample_stats(factor=1)
  base = {
      :rss                      => 1,
      :vsize                    => 2,
      :count                    => 4,
      :heap_used                => 86,
      :heap_length              => 138,
      :heap_increment            =>52,
      :heap_live_num             =>34768,
      :heap_free_num             =>22099,
      :heap_final_num            =>0,
      :total_allocated_object    =>68540,
      :total_freed_object        =>33772
    }
  sample = {}
  base.each { |k,v| sample[k] = v * factor }
  sample
end

def stub_gcstat_delta(request, controller, action, factor=1)
  request.stub(:request) { {:controller => controller, :action => action} }
  MemoryTracker::GcStatDelta.any_instance.stub(:stats) { sample_stats(factor) }
end

module MemoryTracker
  module LiveStore
    describe Manager do
      def start_time
        Time.new(2013,01,01,0,0,0)
      end

      it 'should return stats from older window' do
        Time.stub(:now).and_return(start_time)
        manager = Manager.new(60)
        request = Request.new({})
        stub_gcstat_delta(request, 'Boat', 'sail')
        manager.push(request.close)
        Time.stub(:now).and_return(start_time + 10)
        request = Request.new({})
        stub_gcstat_delta(request, 'Car', 'drive', 2)
        manager.push(request.close)
        Time.stub(:now).and_return(start_time + 40)
        request = Request.new({})
        stub_gcstat_delta(request, 'Boat', 'sail', 3)
        manager.push(request.close)

        stats = manager.stats
        stats.fetch('Boat', 'sail', :rss).should == 4
        stats.fetch('Car', 'drive', :rss).should  == 2
      end

      it 'should rotate windows' do
        Time.stub(:now).and_return(start_time)
        manager = Manager.new(60)
        request = Request.new({})
        stub_gcstat_delta(request, 'Boat', 'sail')
        manager.push(request.close)
        Time.stub(:now).and_return(start_time + 10)
        request = Request.new({})
        stub_gcstat_delta(request, 'Car', 'drive', 2)
        manager.push(request.close)
        Time.stub(:now).and_return(start_time + 40)
        request = Request.new({})
        stub_gcstat_delta(request, 'Boat', 'sail', 3)
        manager.push(request.close)
        Time.stub(:now).and_return(start_time + 70)

        stats = manager.stats
        stats.fetch('Boat', 'sail', :rss).should == 3
        stats.fetch('Car', 'drive', :rss).should == 0
      end
    end

    describe StatInterval do

      before :each do
        @interval = LiveStore::StatInterval.new(Time.now, 5*60)
      end

      it 'should accept requests' do
        request = Request.new({})
        request.stub(:request).and_return({ :controller => :Foo, :action => :bar})
        request.close
        request.controller.should == :Foo
        request.action.should == :bar
        @interval.push(request)
      end

      it 'should accumulate one request' do
        req1 = Request.new({})
        req1.close
        stub_gcstat_delta(req1, 'Boat', 'sail')
        @interval.push(req1)
        @interval.stats.should be_a(Stats)
        @interval.stats.fetch('Boat', 'sail', :rss).should == 1
      end

      it 'should accumulate several requests' do
        req1 = Request.new({})
        req1.close
        stub_gcstat_delta(req1, 'Boat', 'sail')
        @interval.push(req1)
        req2 = Request.new({})
        req2.close
        stub_gcstat_delta(req2, 'Boat', 'sail', 2)
        @interval.push(req2)
        req3 = Request.new({})
        req3.close
        stub_gcstat_delta(req3, 'Boat', 'moor', 5)
        @interval.push(req3)
        req4 = Request.new({})
        req4.close
        stub_gcstat_delta(req4, 'Car', 'drive', 1)
        @interval.push(req4)

        stats = @interval.stats
        stats.fetch('Boat', 'sail', :rss).should   == 3
        stats.fetch('Boat', 'sail', :count).should == 12
        stats.fetch('Boat', 'moor', :rss).should   == 5
        stats.fetch('Boat', 'moor', :count).should == 20
        stats.fetch('Car', 'drive', :rss).should   == 1
        stats.fetch('Car', 'drive', :count).should == 4
      end

      it 'should be enumerable' do
        req1 = Request.new({})
        req1.close
        stub_gcstat_delta(req1, 'Boat', 'sail')
        @interval.push(req1)
        req2 = Request.new({})
        req2.close
        stub_gcstat_delta(req2, 'Boat', 'moor')
        @interval.push(req2)

        @interval.size.should == 2
        @interval.to_a.should include(['Boat', 'sail', sample_stats])
        @interval.to_a.should include(['Boat', 'moor', sample_stats])
      end
    end
  end

end