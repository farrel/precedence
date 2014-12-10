require('lib/precedence/activity')

class TC_Activity < Test::Unit::TestCase #:nodoc:

	def setup
		@activity1 = Precedence::Activity.new(:activity1) do |act1|
			act1.expected_duration = 1;act1.description="Activity One"
		end
		@activity2 = Precedence::Activity.new(:activity2) do |act2|
			act2.expected_duration = 2;act2.description = "Activity Two"
		end
		@activity3 = Precedence::Activity.new(:activity3) do |act3|
			act3.expected_duration = 3;act3.description = "Activity Three"
		end
		@activity4 = Precedence::Activity.new(:activity4) do |act4|
			act4.expected_duration = 4;act4.description = "Activity Four"
		end
		@activity5 = Precedence::Activity.new(:activity5) do |act5|
			act5.expected_duration = 5;act5.description = "Activity Three"
		end
		@activity6 = Precedence::Activity.new(:activity6) do |act6|
			act6.expected_duration = 6;act6.description = "Activity Six"
		end
		@activity7 = Precedence::Activity.new(:activity7) do |act7|
			act7.expected_duration = 7;act7.description = "Activity Seven"
		end
		@activity8 = Precedence::Activity.new(:activity8) do |act8|
			act8.expected_duration = 8;act8.description = "Activity Eight"
		end
	end
	
	def teardown
		@activity1 = nil
		@activity2 = nil
		@activity3 = nil
		@activity4 = nil
		@activity5 = nil
		@activity6 = nil
		@activity7 = nil
		@activity8 = nil
	end	

		
	def test_initialize	
		assert_raises(RuntimeError) do
			Precedence::Activity.new(:start)
		end		
		assert_raises(RuntimeError) do
			Precedence::Activity.new(:finish)
		end
		
		prec = nil
		assert_nothing_raised do
			prec = Precedence::Activity.new(:reference)
		end
		assert_equal(:reference.to_s, prec.reference)
		assert_equal("",prec.description)
		assert_equal(0,prec.duration)
		assert_equal([],prec.post_activities)
		assert_equal([],prec.pre_activities)
		
		assert_nothing_raised do
			prec = Precedence::Activity.new(:reference) do |act|
				act.expected_duration = 1
			end
		end
		assert_equal(:reference.to_s, prec.reference)
		assert_equal("", prec.description)
		assert_equal(1,prec.duration)
		assert_equal([],prec.post_activities)
				assert_equal([],prec.pre_activities)
		
		assert_nothing_raised do
			prec = Precedence::Activity.new(:reference) do |act|
				act.expected_duration = 1
				act.description = "description"
			end
		end
		assert_equal(:reference.to_s, prec.reference)
		assert_equal("description", prec.description)
		assert_equal(1,prec.duration)
		assert_equal([],prec.post_activities)
		assert_equal([],prec.pre_activities)
		
		prec2 = nil
		assert_nothing_raised do
			prec2 = Precedence::Activity.new(:reference) do |act|
				act.expected_duration = 1
				act.description = "description"
				act.add_post_activities(prec)
			end
		end
		assert_equal(:reference.to_s, prec2.reference)
		assert_equal("description", prec2.description)
		assert_equal(1,prec2.duration)
		assert_equal([prec],prec2.post_activities)
		assert_equal([prec2],prec.pre_activities)
		
		prec3 = nil
		assert_nothing_raised do
			prec3 = Precedence::Activity.new(:reference) do |act|
				act.expected_duration = 1
				act.description = "description"
			end
		end
		assert_nothing_raised do
			prec2 = Precedence::Activity.new(:reference) do |act|
				act.expected_duration = 1
				act.description = "description"
				act.add_post_activities(prec)
				act.add_pre_activities(prec3)
			end
		end
		assert_equal(:reference.to_s, prec2.reference)
		assert_equal("description", prec2.description)
		assert_equal(1,prec2.duration)
		assert_equal([prec],prec2.post_activities)
		assert_equal([prec3],prec2.pre_activities)
		
		assert_nothing_raised do 
			prec = Precedence::Activity.new('reference') do |act|
				act.resources['coffee'] = 10.0
				act.resources['sugar'] = 50.0
			end
		end
		assert_equal(:reference.to_s,prec.reference)
		assert_equal(10,prec.resources['coffee'])
		assert_equal(50,prec.resources['sugar'])
	end
	
	def test_to_a
		assert_equal([@activity1],@activity1.to_a)
	end
	
	def test_add_post_activities
		assert_nothing_raised do
			@activity1.add_post_activities(@activity2)
		end
		assert_equal(@activity2.to_a,@activity1.post_activities)
		assert_equal(@activity1.to_a,@activity2.pre_activities)
		
		assert_nothing_raised do
			@activity1.add_post_activities(@activity2)
		end
		assert_equal(1,@activity1.post_activities.size)		
		assert_equal(1,@activity2.pre_activities.size)
		
		assert_nothing_raised do
			@activity1.add_post_activities(@activity3,@activity4)
		end
		assert_equal([@activity2,@activity3,@activity4],
			@activity1.post_activities)
		assert_equal(@activity1.to_a,@activity3.pre_activities)
		assert_equal(@activity1.to_a,@activity4.pre_activities)
	end
	
	def test_add_pre_activities
		assert_nothing_raised do
			@activity1.add_pre_activities(@activity2)
		end
		assert_equal(@activity2.to_a,@activity1.pre_activities)
		assert_equal(@activity1.to_a,@activity2.post_activities)
		
		assert_nothing_raised do
			@activity1.add_pre_activities(@activity2)
		end
		assert_equal(1,@activity1.pre_activities.size)		
		assert_equal(1,@activity2.post_activities.size)
		
		assert_nothing_raised do
			@activity1.add_pre_activities(@activity3,@activity4)
		end
		assert_equal([@activity2,@activity3,@activity4],
			@activity1.pre_activities)
		assert_equal(@activity1.to_a,@activity3.post_activities)
		assert_equal(@activity1.to_a,@activity4.post_activities)
	end
	
	def test_remove_post_activities
		@activity1.add_post_activities(@activity2)
		assert_nothing_raised do
			@activity1.remove_post_activities(@activity2)
		end
		assert_equal([],@activity1.post_activities)
		assert_equal([],@activity2.pre_activities)
		
		@activity1.add_post_activities(@activity2,@activity3)
		assert_nothing_raised do
			@activity1.remove_post_activities(@activity2,@activity3)
		end
		assert_equal([],@activity1.post_activities)
		assert_equal([],@activity2.pre_activities)
		assert_equal([],@activity3.pre_activities)
	end
	
	def test_remove_pre_activities
		@activity1.add_pre_activities(@activity2)
		assert_nothing_raised do
			@activity1.remove_pre_activities(@activity2)
		end
		assert_equal([],@activity1.pre_activities)
		assert_equal([],@activity2.post_activities)
		
		@activity1.add_pre_activities(@activity2,@activity3)
		assert_nothing_raised do
			@activity1.remove_pre_activities(@activity2,@activity3)
		end
		assert_equal([],@activity1.pre_activities)
		assert_equal([],@activity2.post_activities)
		assert_equal([],@activity3.post_activities)
	end
	
	def test_earliest_finish
		assert_equal(1,@activity1.earliest_finish)
		
		# a1-a2
		@activity1.add_post_activities(@activity2)
		assert_equal(3,@activity2.earliest_finish)
		
		# a1-a3-a4
		#  '-a2-'
		@activity1.add_post_activities(@activity3)
		@activity3.add_post_activities(@activity4)
		@activity2.add_post_activities(@activity4)
		assert_equal(8,@activity4.earliest_finish)			
	end
	
	def test_latest_finish
		assert_equal(1,@activity1.latest_finish)
		
		# a1-a2
		@activity1.add_post_activities(@activity2)
		assert_equal(3,@activity2.latest_finish)
		
		# a1---a3---a4
		#    '-a2-'
		@activity1.add_post_activities(@activity3)
		@activity3.add_post_activities(@activity4)
		@activity2.add_post_activities(@activity4)
		assert_equal(2,@activity2.latest_start)
	end
	
	def test_on_critical_path?
		# a1-a2
		@activity1.add_post_activities(@activity2)
		assert_equal(true,@activity1.on_critical_path?)
		assert_equal(true,@activity2.on_critical_path?)
		
		# a1---a3---a4
		#    '-a2-'
		@activity1.add_post_activities(@activity3)
		@activity3.add_post_activities(@activity4)
		@activity2.add_post_activities(@activity4)
		assert_equal(true,@activity1.on_critical_path?)
		assert_equal(false,@activity2.on_critical_path?)
		assert_equal(true,@activity3.on_critical_path?)
		assert_equal(true,@activity4.on_critical_path?)
	end
	
	def test_total_float
		# a1---a3---a4
		#    '-a2-'
		@activity1.add_post_activities(@activity2)
		@activity1.add_post_activities(@activity3)
		@activity3.add_post_activities(@activity4)
		@activity2.add_post_activities(@activity4)

		assert_equal(0,@activity1.total_float)
		assert_equal(0,@activity3.total_float)
		assert_equal(0,@activity4.total_float)
		assert_equal(1,@activity2.total_float)		
	end
	
	def test_early_total_floats
		# a1-a3------.      
		# a2---a4-a6---a8
		#    '-a5-a7-'
		@activity1.expected_duration = 1
		@activity2.expected_duration = 3
		@activity3.expected_duration = 2
		@activity4.expected_duration = 4
		@activity5.expected_duration = 2
		@activity6.expected_duration = 1
		@activity7.expected_duration = 2
		@activity8.expected_duration = 4
		
		@activity1.add_post_activities(@activity3)
		@activity2.add_post_activities(@activity4,@activity5)
		@activity3.add_post_activities(@activity8)
		@activity4.add_post_activities(@activity6)
		@activity5.add_post_activities(@activity7)
		@activity6.add_post_activities(@activity8)
		@activity7.add_post_activities(@activity8)
		
		assert_equal(true,@activity2.on_critical_path?)
		assert_equal(true,@activity4.on_critical_path?)
		assert_equal(true,@activity6.on_critical_path?)
		assert_equal(true,@activity8.on_critical_path?)
		
		assert_equal(false,@activity1.on_critical_path?)
		assert_equal(false,@activity3.on_critical_path?)
		assert_equal(false,@activity5.on_critical_path?)
		assert_equal(false,@activity7.on_critical_path?)
		
		assert_equal(0,@activity1.earliest_start)
		assert_equal(5,@activity1.latest_start)
		assert_equal(1,@activity1.earliest_finish)
		assert_equal(6,@activity1.latest_finish)
		assert_equal(5,@activity1.total_float)
		assert_equal(0,@activity1.early_float)
		
		assert_equal(0,@activity2.earliest_start)
		assert_equal(0,@activity2.latest_start)
		assert_equal(3,@activity2.earliest_finish)
		assert_equal(3,@activity2.latest_finish)
		assert_equal(0,@activity2.total_float)
		assert_equal(0,@activity2.early_float)

		assert_equal(1,@activity3.earliest_start)
		assert_equal(6,@activity3.latest_start)
		assert_equal(3,@activity3.earliest_finish)
		assert_equal(8,@activity3.latest_finish)
		assert_equal(5,@activity3.total_float)
		assert_equal(5,@activity3.early_float)
		
		assert_equal(3,@activity4.earliest_start)
		assert_equal(3,@activity4.latest_start)
		assert_equal(7,@activity4.earliest_finish)
		assert_equal(7,@activity4.latest_finish)
		assert_equal(0,@activity4.total_float)
		assert_equal(0,@activity4.early_float)
		
		assert_equal(3,@activity5.earliest_start)
		assert_equal(4,@activity5.latest_start)
		assert_equal(5,@activity5.earliest_finish)
		assert_equal(6,@activity5.latest_finish)
		assert_equal(1,@activity5.total_float)
		assert_equal(0,@activity5.early_float)
		
		assert_equal(7,@activity6.earliest_start)
		assert_equal(7,@activity6.latest_start)
		assert_equal(8,@activity6.earliest_finish)
		assert_equal(8,@activity6.latest_finish)
		assert_equal(0,@activity6.total_float)
		assert_equal(0,@activity6.early_float)
		
		assert_equal(5,@activity7.earliest_start)
		assert_equal(6,@activity7.latest_start)
		assert_equal(7,@activity7.earliest_finish)
		assert_equal(8,@activity7.latest_finish)
		assert_equal(1,@activity7.total_float)
		assert_equal(1,@activity7.early_float)
		
		assert_equal(8,@activity8.earliest_start)
		assert_equal(8,@activity8.latest_start)
		assert_equal(12,@activity8.earliest_finish)
		assert_equal(12,@activity8.latest_finish)
		assert_equal(0,@activity8.total_float)
		assert_equal(0,@activity8.early_float)		
	end
	
	def test_to_s
		assert_equal("Reference: activity1\nDescription: Activity One\n"+
			"Duration: 1.0",@activity1.to_s)

		@activity1.add_pre_activities(@activity2,@activity3)
		assert_equal("Reference: activity1\nDescription: Activity One\n"+
			"Duration: 1.0\nDepends on:\n activity2,activity3",@activity1.to_s)			
	end
		
	def test_to_yaml
		@activity1.resources['coffee'] = 5
		@activity1.resources['sugar'] = 10
		@activity1.minimum_duration = 1.0
		@activity1.maximum_duration = 4.0
		reference,activity = YAML::load(@activity1.to_yaml).to_a[0]

		assert_equal(@activity1.reference,reference)
		assert_equal(@activity1.description,activity['description'].to_s)
		assert_equal(@activity1.expected_duration,activity['expected duration'].to_f)	
		assert_equal(5,activity['resources']['coffee'])	
		assert_equal(10,activity['resources']['sugar'])
		assert_equal(@activity1.minimum_duration,activity['minimum duration'].to_f)
		assert_equal(@activity1.maximum_duration,activity['maximum duration'].to_f)			
	end
	
	def test_from_yaml
		@activity1.resources['coffee'] = 5
		@activity1.resources['sugar'] = 10
		@activity1.minimum_duration = 1.0
		@activity1.maximum_duration = 4.0
		activity = nil
		assert_nothing_raised do
			activity = Precedence::Activity.from_yaml(@activity1.to_yaml)
		end
		assert_equal(true,activity.instance_of?(Precedence::Activity))
		assert_equal(@activity1.reference,activity.reference)
		assert_equal(@activity1.description,activity.description)
		assert_equal(@activity1.expected_duration,activity.expected_duration)
		assert_equal(@activity1.minimum_duration,activity.minimum_duration)
		assert_equal(@activity1.maximum_duration,activity.maximum_duration)
		assert_equal(@activity1.resources,activity.resources)			
	end
	
	def test_eql
		assert_equal(false,@activity1 == @activity2)
		activity1 = Precedence::Activity.new(:activity1) do |act|
			act.expected_duration = 1
			act.description = "Activity Uno"
		end
		assert_equal(true,@activity1 == activity1)
		activity1.expected_duration = 2
		assert_equal(false,@activity1 == activity1)
	end
	
	def test_resources
		@activity1.resources['coffee'] = "2.5"
		assert_equal(2.5,@activity1.resources['coffee'])
		assert_equal(@activity1.resources['coffee'],@activity1.resources[:coffee])
	end
	
	def test_active_on?
		@activity1.add_post_activities(@activity2)
		@activity1.add_post_activities(@activity3)
		@activity2.add_post_activities(@activity4)
		@activity3.add_post_activities(@activity4)
		
		assert(@activity1.active_on?(0))
		assert(@activity1.active_on?(0.5))
		assert(!@activity1.active_on?(1))
		
		assert(@activity2.active_on?(1))
		assert(@activity3.active_on?(1))
		
		assert(!@activity2.active_on?(3))
		assert(@activity3.active_on?(3))
		
		assert(!@activity3.active_on?(4))
		assert(@activity4.active_on?(4))
		
		assert(!@activity4.active_on?(8))		
	end	
	
	def test_active_during?
		@activity1.add_post_activities(@activity2)
		@activity1.add_post_activities(@activity3)
		@activity2.add_post_activities(@activity4)
		@activity3.add_post_activities(@activity4)
		
		assert(@activity1.active_during?(0..1))
		assert(!@activity1.active_during?(1..2))
		
		assert(@activity2.active_during?(1..2))
		assert(@activity2.active_during?(1..2))
		
		assert(@activity3.active_during?(1..2))
		
	end
	
	def test_duration_type
		activity = Precedence::Activity.new('act1') do |activity|
			activity.expected_duration = 2
			activity.maximum_duration = 4
			activity.minimum_duration = 1
		end
		assert_equal(13.0/6,activity.mean_duration)
		assert_equal(activity.duration,activity.expected_duration)
		activity.duration_type = Precedence::Activity::MAXIMUM_DURATION
		assert_equal(activity.duration,activity.maximum_duration)
		activity.duration_type = Precedence::Activity::MINIMUM_DURATION
		assert_equal(activity.duration,activity.minimum_duration)				
	end
	
	def test_variance_standard_deviation
		@activity1.minimum_duration = 1
		@activity1.expected_duration = 2
		@activity1.maximum_duration = 4
		
		assert_equal(0.25,@activity1.variance)
		assert_equal(0.5,@activity1.standard_deviation)
	end
end

class TC_StartFinishActivity < Test::Unit::TestCase
	def setup
		@start = Precedence::StartActivity.new
		@finish = Precedence::FinishActivity.new
	end
	
	def teardown
		@start = nil
		@finish = nil
	end
	
	def test_new
		start = nil
		assert_nothing_raised do
			start = Precedence::StartActivity.new
		end
		assert_equal('start',start.reference)
		assert_equal('start',start.description)
		
		finish = nil
		assert_nothing_raised do
			finish = Precedence::FinishActivity.new
		end
		assert_equal('finish',finish.reference)
		assert_equal('finish',finish.description)
		
		assert_nothing_raised do
			start = Precedence::StartActivity.new("Begin")
		end
		assert_equal('start',start.reference)
		assert_equal('Begin',start.description)
		
		assert_nothing_raised do
			finish = Precedence::FinishActivity.new("End")
		end
		assert_equal('finish',finish.reference)
		assert_equal('End',finish.description)
	end
	
	def test_to_yaml
		reference,activity = nil,nil	
		assert_nothing_raised do		
			reference,activity = YAML::load(@start.to_yaml).to_a[0]		
		end
		assert_equal('start',reference)		
		
		assert_nothing_raised do
			reference,activity = YAML::load(Precedence::StartActivity.new("Start").to_yaml).to_a[0]
		end
		assert_equal('start',reference)
		assert_equal('Start',activity['description'])
		
	end
	
	def test_from_yaml
		start = nil
		assert_nothing_raised do
			start = Precedence::StartActivity.from_yaml(@start.to_yaml)
		end
		assert_equal(true,start.instance_of?(Precedence::StartActivity))
		assert_equal(@start.reference,start.reference)
		assert_equal(@start.description,start.description)
		assert_equal(@start.duration,start.duration)
		
		finish = nil
		assert_nothing_raised do
			finish = Precedence::FinishActivity.from_yaml(@finish.to_yaml)
		end
		assert_equal(true,finish.instance_of?(Precedence::FinishActivity))
		assert_equal(@finish.reference,finish.reference)
		assert_equal(@finish.description,finish.description)
		assert_equal(@finish.duration,finish.duration)
		
		act = Precedence::Activity.new('act1') do |act|
			act.expected_duration = 3
			act.description = 'Activity One'
		end
		assert_raises(RuntimeError) do
			Precedence::StartActivity.from_yaml(act.to_yaml)
		end
		
		assert_raises(RuntimeError) do
			Precedence::FinishActivity.from_yaml(act.to_yaml)
		end		
	end
	
	def test_register
		act = Precedence::Activity.new('act1') do |act|
			act.expected_duration = 1
			act.description = 'Activity 1'
		end
		assert_raises(RuntimeError) do
			act.add_pre_activities(@finish)
		end
		assert_equal(0,act.post_activities.size)
		
		assert_raises(RuntimeError) do
			act.add_post_activities(@start)
		end
		assert_equal(0,act.pre_activities.size)				
	end
end