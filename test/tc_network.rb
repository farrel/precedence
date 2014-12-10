require('lib/precedence/network')

class TC_ActivityHash < Test::Unit::TestCase
	def setup
		@start = Precedence::StartActivity.new
		@finish = Precedence::FinishActivity.new
	end
	def test_all
		activityHash = nil
		assert_nothing_raised do			
			activityHash = Precedence::Utilities::ActivityHash.new(@start,@finish)
		end
		
		assert_nothing_raised do
			activityHash[:test] = "test"
		end
		assert_equal("test",activityHash[:test])
		assert_equal("test",activityHash['test'])		
	end
end

class TC_Network < Test::Unit::TestCase

	def setup
		@network = Precedence::Network.new
		@activity1 = Precedence::Activity.new('a1') do |act1|
			act1.expected_duration = 1
			act1.description = 'Activity1'
		end
		@activity2 = Precedence::Activity.new('a2') do |act2|
			act2.expected_duration = 2
			act2.description = 'Activity2'
		end
		@activity3 = Precedence::Activity.new('a3') do |act3|
			act3.expected_duration = 3
			act3.description = 'Activity3'
		end
	end

	def test_initialize
		net = nil
		assert_nothing_raised do 
			net = Precedence::Network.new
		end
		assert_equal(0,net.activities.size)
		assert_equal('start',net.activities[:start].reference)
		assert_equal('finish',net.activities[:finish].reference)

	end
	
	def test_new_activity
		assert_raises(ArgumentError) do
			@network.new_activity()
		end
	
		assert_nothing_raised do
			@network.new_activity('a1') do |act|
				act.expected_duration = 1
			end
		end
		assert_equal(1,@network.activities.size)
		assert_equal('a1',@network.activities['a1'].reference)
		assert_equal(1,@network.activities['a1'].duration)
		
		assert_nothing_raised do
			@network.new_activity('a2') do |act|
				act.expected_duration = 2
				act.description = 'Activity Two'
			end
		end	
		assert_equal(2,@network.activities.size)
		assert_equal('a2',@network.activities['a2'].reference)
		assert_equal('Activity Two',@network.activities['a2'].description)
		assert_equal(2,@network.activities['a2'].duration)
		
		assert_nothing_raised do
			@network.new_activity('a3') do |act|
				act.expected_duration = 3
				act.description = 'Activity Three'
			end
		end	
		assert_equal(3,@network.activities.size)
		assert_equal('a3',@network.activities['a3'].reference)
		assert_equal('Activity Three',@network.activities['a3'].description)
		assert_equal(3,@network.activities['a3'].duration)
		
		assert_nothing_raised do
			@network.new_activity('a4') do |act|
				act.expected_duration = 4
				act.description = 'Activity Four'
			end
			@network.connect('a4','a3')
		end	
		assert_equal(4,@network.activities.size)
		assert_equal('a4',@network.activities['a4'].reference)
		assert_equal('Activity Four',@network.activities['a4'].description)
		assert_equal(4,@network.activities['a4'].duration)
		assert_equal(1,@network.activities['a4'].post_activities.size)
		assert_equal('a3',@network.activities['a4'].post_activities[0].reference)
		assert_equal('a4',@network.activities['a3'].pre_activities[0].reference)
		
		assert_nothing_raised do
			@network.new_activity('a5') do |act|
				act.expected_duration = 5
				act.description = 'Activity Five'
			end
			@network.connect('a5','a3')
			@network.connect('a4','a5')			
		end	
		assert_equal(5,@network.activities.size)
		assert_equal('a5',@network.activities['a5'].reference)
		assert_equal('Activity Five',@network.activities['a5'].description)
		assert_equal(5,@network.activities['a5'].duration)
		assert_equal(1,@network.activities['a5'].post_activities.size)
		assert_equal(1,@network.activities['a5'].pre_activities.size)
		assert_equal('a3',@network.activities['a5'].post_activities[0].reference)
		assert_equal('a5',@network.activities['a3'].pre_activities[1].reference)
		assert_equal('a4',@network.activities['a5'].pre_activities[0].reference)
		assert_equal('a5',@network.activities['a4'].post_activities[1].reference)
		
		assert_raises(RuntimeError) do
			@network.new_activity('a6') do |act|
				act.expected_duration = 6
				act.description = 'Activity Six'
				@network.connect('a6','a7')
			end
		end
		
		assert_raises(RuntimeError) do
			@network.new_activity('a6') do |act|
				act.expected_duration = 6
				act.description = 'Activity Six'
				@network.connect('a6','a5')
				@network.connect('a6','a7')
			end
		end
		assert_equal(nil,
			@network.activities['a5'].pre_activities.detect do |activity|
											activity.reference == 'a6'
										end)
	
		assert_raises(RuntimeError) do
			@network.new_activity('a6') do |act|
				act.expected_duration = 6
				act.description = 'Activity Six'
				@network.connect('a5','a6')
				@network.connect('a7','a6')
			end
		end
		assert_equal(nil,
			@network.activities['a5'].post_activities.detect do |activity|
											activity.reference == 'a6'
										end)
	end
	
	def test_add_activity
		assert_nothing_raised do
			@network.add_activity(@activity1)
		end
		assert_equal(1,@network.activities.size)
		assert_equal(@activity1,@network.activities[@activity1.reference])
		
		assert_raises(RuntimeError) do
			@network.add_activity(@activity1)
		end
		
		@network = Precedence::Network.new
		@activity1.add_post_activities(@activity2)
		assert_raises(RuntimeError) do
			@network.add_activity(@activity1)
		end	
		assert_equal(0,@network.activities.size)	
	end
	
	def test_connect
		@network.add_activity(@activity1)
		@network.add_activity(@activity2)
		
		assert_nothing_raised do
			@network.connect(@activity1.reference,@activity2.reference)
		end
		assert_equal(1,@activity1.post_activities.size)
		assert_equal(1,@activity2.pre_activities.size)
		assert_equal('a2',@activity1.post_activities[0].reference)
		assert_equal('a1',@activity2.pre_activities[0].reference)
		
		assert_raises(RuntimeError) do
			@network.connect(@activity1.reference,'bogus reference')
		end
		assert_equal(1,@activity1.post_activities.size)
		assert_equal('a2',@activity1.post_activities[0].reference)
		
		assert_raises(RuntimeError) do
			@network.connect('bogus reference','a2')
		end
		assert_equal(1,@activity2.pre_activities.size)
		assert_equal('a1',@activity2.pre_activities[0].reference)
	end	
	
	def test_disconnect
		@network.add_activity(@activity1)
		@network.add_activity(@activity2)
		@network.add_activity(@activity3)
		@network.connect(@activity1.reference,@activity2.reference)
		@network.connect(@activity1.reference,@activity3.reference)
		
		assert_nothing_raised do 
			@network.disconnect(@activity1.reference,@activity2.reference,@activity3.reference)
		end
		assert_equal(0,@activity1.post_activities.size)
		assert_equal(0,@activity2.pre_activities.size)
		assert_equal(0,@activity3.pre_activities.size)
		
		@network.connect(@activity1.reference,@activity2.reference)
		
		assert_raises(RuntimeError) do
			@network.disconnect(@activity1.reference,'bogus reference')
		end
		assert_equal(1,@activity1.post_activities.size)
		
		assert_raises(RuntimeError) do
			@network.disconnect('bogus reference',@activity2.reference)
		end
		assert_equal(1,@activity2.pre_activities.size)
	end
		
	def test_fix_connections!
		@network.add_activity(@activity1)
		@network.add_activity(@activity2)
		@network.add_activity(@activity3)
		@network.connect('start',@activity1.reference)
		@network.connect(@activity1.reference,@activity2.reference)
		@network.connect(@activity3.reference,'finish')
		@network.fix_connections!
		assert_equal(1,@activity2.post_activities.size)
		assert_equal('finish',@activity2.post_activities[0].reference)
		assert_equal(1,@activity3.pre_activities.size)
		assert_equal('start',@activity3.pre_activities[0].reference)		
	end
	
	def test_to_dot
		net = Precedence::Network.new
		net.new_activity('act-1-1') do |act|
			act.expected_duration = 3
			act.description = 'System specification'
		end
		net.new_activity('act-1-2') do |act|
			act.expected_duration = 2
			act.description = 'Review'
		end
		net.new_activity('act-1-3') do |act| 
			act.expected_duration = 2
			act.description = 'System re-specification'
		end
		net.new_activity('act-2-1') do |act|
			act.expected_duration = 3
			act.description = 'Test tool design'
		end
		net.new_activity('act-2-2') do |act|
			act.expected_duration = 5
			act.description = 'Test tool implementation'
		end
		net.new_activity('act-3-1') do |act|
			act.expected_duration = 3
			act.description = 'System design'
		end
		net.new_activity('act-3-2') do |act|
			act.expected_duration = 12
			act.description = 'System implementation'
		end
		net.new_activity('act-2-3') do |act|
			act.expected_duration = 10
			act.description = 'System testing'
		end
		net.connect('act-1-1','act-1-2')
		net.connect('act-1-2','act-1-3')
		net.connect('act-1-3','act-3-1')
		net.connect('act-1-2','act-2-1')
		net.connect('act-2-1','act-2-2')
		net.connect('act-2-2','act-3-2')
		net.connect('act-3-1','act-3-2')
		net.connect('act-3-2','act-2-3')
		net.fix_connections!

		assert_nothing_raised do
			File.open('test_to_dot.dot',File::CREAT|File::TRUNC|File::WRONLY) do|f|
				f.puts(net.to_dot)
			end
		end
		$stdout.puts("\nTest dot file test_to_dot.dot file generated.")
		
		if system("dot","-Tpng","-otest_to_dot.png","test_to_dot.dot")
			$stdout.puts("Test png file test_to_dot.png files generated.")
		end
	end
	
	def test_to_yaml
		@activity1.resources['coffee'] = 5
		@activity1.resources['sugar'] = 10
		@network.add_activity(@activity1)
		@activity2.resources['coffee'] = 7.5
		@network.add_activity(@activity2)
		@network.connect('a1','a2')
		@network.fix_connections!
		activities=[]
		yamlArray = YAML::load_documents(@network.to_yaml) do |doc|			
			activities << Precedence::Activity.from_yaml_object(doc)
		end
		assert_equal(2,activities.size)

		act1 = activities.detect do |activity|
			activity.reference == 'a1'
		end
		assert_equal(@activity1.reference,act1.reference)		
		assert_equal(@activity1.expected_duration,act1.expected_duration)
		assert_equal(@activity1.description,act1.description)
		
		act2 = activities.detect do |activity|
			activity.reference == 'a2'
		end
		assert_equal(@activity2.reference,act2.reference)
		assert_equal(@activity2.expected_duration,act2.expected_duration)
		assert_equal(@activity2.description,act2.description)
	
		assert_nothing_raised do
			File.open('test_to_yaml.yaml',File::CREAT|File::TRUNC|File::WRONLY) do|f|
				f.puts(@network.to_yaml)
			end
		end
		$stdout.puts("\nTest yaml file test_to_yaml.yaml file generated.")
	end
	
	def test_from_yaml
		@network.add_activity(@activity1)
		@network.add_activity(@activity2)
		@network.add_activity(@activity3)
		@network.connect('a1','a2')
		@network.connect('a1','a3')

		
		network = Precedence::Network.from_yaml(@network.to_yaml)
		assert_equal(3,network.activities.size)
		network.fix_connections!

		start = network.activities['start']
		assert_equal('start',start.reference)
		assert_equal(0,start.expected_duration)
		assert_equal(1,start.post_activities.size)
		assert_equal(0,start.pre_activities.size)
		assert_equal(@activity1,start.post_activities[0])
		
		a1 = network.activities['a1']
		assert_equal('a1',a1.reference)
		assert_equal(1,a1.expected_duration)
		assert_equal('Activity1',a1.description)
		assert_equal(2,a1.post_activities.size)
		assert_equal(true,(((a1.post_activities[0].reference == 'a2') and (a1.post_activities[1].reference == 'a3'))or
						((a1.post_activities[1].reference == 'a2') and (a1.post_activities[0].reference == 'a3'))))
						
		a2 = network.activities['a2']
		assert_equal('a2',a2.reference)
		assert_equal(2,a2.expected_duration)
		assert_equal('Activity2',a2.description)
		assert_equal(1,a2.post_activities.size)
		assert_equal(1,a2.pre_activities.size)
		assert_equal('a1',a2.pre_activities[0].reference)
		assert_equal('finish',a2.post_activities[0].reference)
		
		a3 = network.activities['a3']
		assert_equal('a3',a3.reference)
		assert_equal(3,a3.expected_duration)
		assert_equal('Activity3',a3.description)
		assert_equal(1,a3.post_activities.size)
		assert_equal(1,a3.pre_activities.size)
		assert_equal('a1',a3.pre_activities[0].reference)
		assert_equal('finish',a3.post_activities[0].reference)
		
		finish = network.activities['finish']
		assert_equal('finish',finish.reference)
		assert_equal(0,finish.expected_duration)
		assert_equal(0,finish.post_activities.size)
		assert_equal(2,finish.pre_activities.size)
		assert_equal(true,(((finish.pre_activities[0].reference == 'a2') and (finish.pre_activities[1].reference == 'a3'))or
						((finish.pre_activities[1].reference == 'a2') and (finish.pre_activities[0].reference == 'a3'))))					
	end
		
	def test_activities_at_time
		@network.add_activity(@activity1)
		@network.add_activity(@activity2)
		@network.add_activity(@activity3)
		@network.connect('a1','a2')
		@network.connect('a1','a3')
		@network.fix_connections!		
		
		assert_equal([@activity1],@network.activities_at_time(0.5))
		assert_equal([@activity2,@activity3],@network.activities_at_time(2.5))
		assert_equal([@activity3],@network.activities_at_time(3))
	end
	
	def test_activities_during_time
		@network.add_activity(@activity1)
		@network.add_activity(@activity2)
		@network.add_activity(@activity3)
		@network.connect('a1','a2')
		@network.connect('a1','a3')
		@network.fix_connections!
		
		assert_equal([@activity1],@network.activities_during_time(0..1.0))
		assert_equal([@activity1,@activity2,@activity3],@network.activities_during_time(0..2.0))
		assert_equal([@activity2,@activity3],@network.activities_during_time(1.0..2.0))
		assert_equal([@activity2,@activity3],@network.activities_during_time(1.5..2.5))
		
		assert_equal([],@network.activities_during_time(4.0..5.0))			
	end
	
	def test_each_time
		@network.add_activity(@activity1)
		@network.add_activity(@activity2)
		@network.add_activity(@activity3)
		@network.connect('a1','a2')
		@network.connect('a1','a3')
		@network.fix_connections!				
	
		expected_activities = {0.0=>[@activity1],1.0=>[@activity2,@activity3],
			2.0=>[@activity2,@activity3],3.0=>[@activity3]}
		actual_activities = {}
		
		day = 0.0
		assert_nothing_raised do
			@network.each_time_period do |activities|
				actual_activities[day] = activities
				day += 1
			end
		end
		assert_equal(expected_activities,actual_activities)
		
		actual_activities = {}
		assert_nothing_raised do
			@network.each_time_period_with_index do |activities,index|
				actual_activities[index] = activities
			end
		end
		assert_equal(expected_activities,actual_activities)		
	end
end

