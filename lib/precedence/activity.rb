require('yaml')

module Precedence
  # A representation of an activity in a precedence network. Each activity
  # has a user specified reference, description and duration. When activities
  # are connected (via the add_post/pre_activities functions) then various
  # other properties of the activity can be determined such as it's earliest
  # finish time, float and so on.
  #
  # The activity also has a probabilistic component.
  class Activity
    MEAN_DURATION = :mean_duration
    EXPECTED_DURATION = :expected_duration
    MINIMUM_DURATION = :minimum_duration
    MAXIMUM_DURATION = :maximum_duration

    @duration_type = EXPECTED_DURATION

    EARLIEST_START = :earliest_start
    LATEST_START = :latest_start
    DROP_START = :drop_start

    @start_type = EARLIEST_START

    # A textual description of the activity.
    attr_accessor :description
    # The expected duration of the activity
    attr_accessor :expected_duration
    # The minimum duration of the activity
    attr_accessor :minimum_duration
    # The maximum duration of the activity
    attr_accessor :maximum_duration
    # A unique reference for this activity.
    attr_reader :reference
    # The collection of activites that are dependent on the completion of
    # this activity.
    attr_reader :post_activities
    # The collection of activities that this activity depends on before it
    # can begin executing.
    attr_reader :pre_activities
    # A collection of resources that are used by this activitity. Stating
    # that
    #  activity.resources['concrete'] = 5
    # indicates that the activity will use 5 units of concrete per time
    # period.
    attr_reader :resources
    # Sets what the duration method should return. Can be set to one of:
    # * EXPECTED_DURATION
    # * MAXIMUM_DURATION
    # * MINIMUM_DURATION
    # * MEAN_DURATION
    # Initially set to the expected duration
    attr_accessor :duration_type
    # Sets what the start attribute should return can be set to one of:
    # * EARLIEST_START
    # * LATEST_START
    # * DROP_START
    # Initially set to the earliest start
    attr_accessor :start_type

    # Creates a new activity. The only required field is the reference.
    # The description, duration can be set in the block, which will have
    # as a parameter the newly created activity. If they are not set in the
    # block they will have as values "" and 0 respectively. Post- and
    # pre-activities can also be set in the block by using the
    # Activity.add_post_activities and Activity.add_pre_activities methods.
    #
    # *Note*: When assigning a reference for an activity
    # StartActivity::REFERENCE and FinishActivity::REFERENCE are reserved
    # for internal usage.
    def initialize(reference, &block)
      reference.respond_to?(:to_s) ? nil : raise('Parameter reference'\
				"must respond to 'to_s'.")
      reference = reference.to_s
      if (reference != Precedence::StartActivity::REFERENCE) &&
         (reference != Precedence::FinishActivity::REFERENCE)
        @reference = reference.to_s
      else
        raise "Activity reference '#{reference}' is reserved."
      end

      @description = ''
      @post_activities = []
      @pre_activities = []
      @resources = Precedence::Utilities::ResourceHash.new
      @expected_duration = 0
      @minimum_duration = 0
      @maximum_duration = 0
      @duration_type = EXPECTED_DURATION
      @start_type = EARLIEST_START

      # Call the block if it is present
      block ? yield(self) : nil

      # Type conversion
      @expected_duration = @expected_duration.to_f
      @minimum_duration = @minimum_duration.to_f
      @maximum_duration = @maximum_duration.to_f
    end

    # Adds the activities in the parameter list to the post_activities
    # collection of this activity and also adds this activity to the
    # pre_activities collection of each of the activities.
    #
    # *Note*: When using the Network class it is better to use
    # Network.connect than Activity.add_pre_activities or
    # Activity.add_post_activities directly.
    def add_post_activities(*post_acts) #:nodoc:
      post_acts.flatten!
      post_acts.each do |activity|
        activity.register_pre_activity(self)
        register_post_activity(activity)
      end
      post_acts
    end

    # Adds the activities in the parameter list to the pre_activities
    # collection of this activity and also adds this activity to the
    # post_activities collection of each of the activities.
    #
    # *Note*: When using the Network class it is better to use
    # Network.connect than Activity.add_pre_activities or
    # Activity.add_post_activities directly.
    def add_pre_activities(*pre_acts) #:nodoc:
      pre_acts.flatten!
      pre_acts.each do |activity|
        activity.register_post_activity(self)
        register_pre_activity(activity)
      end
      pre_acts
    end

    # Removes the list of activities from the post_activities collection of
    # the activity.
    def remove_post_activities(*post_acts) #:nodoc:
      post_acts.flatten!
      post_acts.each do |activity|
        activity.deregister_pre_activity(self)
        deregister_post_activity(activity)
      end
      post_acts
    end

    # Removes the list of activities from the pre_activities collection of
    # the activity.
    def remove_pre_activities(*pre_acts) #:nodoc:
      pre_acts.flatten!
      pre_acts.each do |activity|
        activity.deregister_post_activity(self)
        deregister_pre_activity(activity)
      end
      pre_acts
    end

    # The earliest possible time this activity can finish.
    def earliest_finish
      earliest_start + duration
    end

    # The earliest possible time this activity can start.
    def earliest_start
      if pre_activities.empty?
        0.0
      else
        pre_activities.max_by(&:earliest_finish).earliest_finish
      end
    end

    # The latest possible time this activity can start so as not to delay
    # any dependent activities.
    def latest_start
      latest_finish - duration
    end

    # The latest possible time this activity can finish so as not to delay
    # any dependent activities.
    def latest_finish
      if post_activities.empty?
        earliest_finish
      else
        post_activities.min_by(&:latest_start).latest_start
      end
    end

    # The maximum earliest finish of this activities pre-activities.
    def pre_activities_max_earliest_finish #:nodoc:
      if pre_activities.empty?
        0
      else
        pre_activities.max_by(&:earliest_finish).earliest_finish
      end
    end

    # The minimum earliest start of this activities post-activities.
    def post_activities_min_earliest_start #:nodoc:
      if post_activities.empty?
        latest_finish
      else
        post_activities.min_by(&:earliest_start).earliest_start
      end
    end

    # If the activity is on the critical path returns true, returns false
    # otherwise.
    def on_critical_path?
      earliest_finish == latest_finish
    end

    # The amount of float this activity has such that it does not delay
    # the completion of the entire precedence network.
    def total_float
      latest_finish - earliest_finish
    end

    # The amount of float this activity has if all preceding and succeeding
    # activities start as early as possible.
    #
    # *Note*: In almost all practical cases this is the same as if all
    # preceding and  successing activities start as lates as possible and so
    # no late_float method is defined.
    def early_float
      post_activities_min_earliest_start -
        pre_activities_max_earliest_finish	- duration
    end

    # Register this activity as a post-activity on the parameter.
    def register_post_activity(activity) #:nodoc:
      unless post_activities.find do |post_activity|
               activity.reference == post_activity.reference
             end
        post_activities << activity
      end
    end

    # Register this activity as a pre-activity on the parameter.
    def register_pre_activity(activity) #:nodoc:
      unless pre_activities.find do |pre_activity|
               activity.reference == pre_activity.reference
             end
        pre_activities << activity
      end
    end

    # Deregister this activity as a post-activity on the parameter.
    def deregister_post_activity(activity) #:nodoc:
      if post_activities.find do |post_activity|
           activity.reference == post_activity.reference
         end
        post_activities.delete(activity)
      end
    end

    # Deregister this activity as a pre-activity on the parameter.
    def deregister_pre_activity(activity) #:nodoc:
      if pre_activities.find do |pre_activity|
           activity.reference == pre_activity.reference
         end
        pre_activities.delete(activity)
      end
    end

    # Returns this activity in an Array object.
    def to_a #:nodoc:
      [self]
    end

    # Redefines the inspect method.
    def inspect #:nodoc:
      "#{reference}(#{duration})"
    end

    # Redefines the to_s method
    def to_s #:nodoc:
      "Reference: #{reference}\n"\
				"Description: #{description}\n"\
				"Duration: #{duration}" +	("\nDepends on:\n " unless @pre_activities.empty?).to_s +
        @pre_activities.map(&:reference).join(',')
    end

    # Returns a YAML document representing the activity object.
    def to_yaml
      "---\n#{reference}:\n" +	(description.empty? ? '' : "  description: #{description}\n") +	(expected_duration.zero? ? '' : "  expected duration: #{expected_duration}\n") +	(minimum_duration.zero? ? '' : "  minimum duration: #{minimum_duration}\n") +	(maximum_duration.zero? ? '' : "  maximum duration: #{maximum_duration}\n") +	(post_activities.empty? ? '' : "  post activities:\n") +
        (post_activities.map do |activity|
          "    - #{activity.reference}"
        end).join("\n") + "\n" +	(resources.empty? ? '' : "  resources:\n") +	(resources.to_a.map do |resource, value|
                                                                                 "    #{resource}: #{value}"
                                                                               end).join("\n") + "\n"
    end

    # Returns true if two activity objects have the same duration and
    # reference, false otherwise.
    def eql?(other)
      if (reference == other.reference) &&
         (duration == other.duration)
        return true
      end
      false
    end

    alias == eql?

    # Returns true if the activity is active during the time given.
    #
    # *Note*: If an activity has a start of x and a finish of y, then
    #  activity.active_on?(x)
    # will return true, while
    #  activity.active_on?(y)
    # will return false.
    def active_on?(time)
      duration_range === time
    end

    # Returns true if the activity is active during the range given.
    #
    # *Note*: If a range given includes the last element
    # (range.include_end? == true) it is treated as a range that does
    # not include the last element
    def active_during?(range)
      range = Range.new(range.begin, range.end, true) unless range.exclude_end?

      (range === start) ||
        ((finish > range.begin) && (finish < range.end)) ||
        ((start < range.begin) && (finish > range.begin))
    end

    # Returns a range object representing the duration of the activity. The
    # range object return will have range.exclude_end? set to true.
    #
    # Example usage:
    #  activity.duration_range
    def duration_range
      Range.new(start, finish, true)
    end

    # Sets what duration type the activity should use.
    #
    # Example usage:
    #  Activity.duration_type = Activity::MEAN_DURATION
    # will change the duration type to the mean duration for all activities.
    def duration_type=(type) #:nodoc:
      case type
      when MEAN_DURATION, EXPECTED_DURATION,
        MINIMUM_DURATION, MAXIMUM_DURATION
        @duration_type = type
      else
        raise "Duration type '#{type}' is unknown."
      end
    end

    # Returns the duration of the activity dependent on what the
    def duration
      case duration_type
      when MEAN_DURATION
        mean_duration
      when EXPECTED_DURATION
        expected_duration
      when MINIMUM_DURATION
        minimum_duration
      when MAXIMUM_DURATION
        maximum_duration
      else
        raise "Duration type '#{type}' is unknown."
      end
    end

    # Returns the mean duration which is defined as
    #  (4*expected_duration + minimum_duration + maximum_duration)/6
    def mean_duration
      ((4 * expected_duration) + minimum_duration + maximum_duration) / 6.0
    end

    # The variance of the duration of the activity. Defined as
    #  (maximum_duration - minimum_duration)^2/36
    def variance
      standard_deviation**2
    end

    # The standard deviation of the duration of the activity dfined as
    #  (maximum_duraion - minimum_duration) / 6
    def standard_deviation
      (maximum_duration - minimum_duration) / 6.0
    end

    # Sets start type the activity should use.
    #
    # Example usage:
    #  Activity.start_type = Activity::LATEST_START
    # will change the start type to the latest start for all activities.
    def start_type=(type) #:nodoc:
      case type
      when EARLIEST_START, LATEST_START, DROP_START
        @start_type = type
      else
        raise "Start type '#{type}' is unknown."
      end
    end

    # Returns the start time of the activity dependent on what the
    # start_type has been set to.
    def start
      case start_type
      when EARLIEST_START
        earliest_start
      when LATEST_START
        latest_start
      when DROP_START
        drop_start
      else
        raise "Start type '#{type}' is unknown."
      end
    end

    # Returns the finish time of the activity dependent on what the
    # start_type and duration_type have been set to. This is equivalent
    # to calling
    #  activity.start + activity.duration
    def finish
      start + duration
    end

    # Returns an Activity object that is represented by the YAML object.
    # A YAML object is the object returned from a YAML::load or
    # YAML::load_documents method. This method will automatically load
    # a Start/FinishActivity if such a yamlObject is given.
    #
    # *Note*: This method will only restore the reference, varios durations,
    # description and resource parameters. Post-/pre-activities are not
    # restored (they are restored when using Precedence::Network.from_yaml).
    def self.from_yaml_object(yamlObject) #:nodoc:
      reference, activity = yamlObject.to_a[0]
      if reference.to_s == StartActivity::REFERENCE
        return StartActivity.from_yaml_object(yamlObject)
      elsif reference.to_s == FinishActivity::REFERENCE
        return FinishActivity.from_yaml_object(yamlObject)
      else
        return Precedence::Activity.new(reference.to_s) do |act|
          act.expected_duration = activity['expected duration'].to_f
          act.minimum_duration = activity['minimum duration'].to_f
          act.maximum_duration = activity['maximum duration'].to_f
          act.description = activity['description'].to_s
          if activity['resources']
            activity['resources'].each do |resource, value|
              act.resources[resource] = value
            end
          end
        end
      end
    end

    # Returns an Activity object that is represented by a YAML document.
    #
    # *Note*: This method will only restore the reference, various durations,
    # description and resource parameters. Post-/pre-activities are not
    # restored (they are restored when using Precedence::Network.from_yaml).
    def self.from_yaml(yaml)
      from_yaml_object(YAML.safe_load(yaml))
    end

    # Priviliege settings
    protected :register_post_activity, :register_pre_activity
    protected :deregister_post_activity, :deregister_pre_activity

    private :pre_activities_max_earliest_finish
    private :post_activities_min_earliest_start
  end

  # A special activity which signifies the start of a precedence network.
  # It has a duration of 0 and is not allowed to have any pre_activities.
  # It's reference will always be 'start'.
  class StartActivity < Precedence::Activity #:nodoc:
    attr_reader :expected_duration, :maximum_duration, :minimum_duration

    # Reference for the StartActivity
    REFERENCE = 'start'.freeze

    # Creates a new start activity.
    def initialize(description = nil)
      @reference = REFERENCE
      @description = if description.nil?
                       @reference
                     else
                       description.to_s
                     end
      @expected_duration = 0
      @minimum_duration = 0
      @maximum_duration = 0
      @post_activities = []
      @pre_activities = []
      @resources = {}
      @duration_type = EXPECTED_DURATION
      @start_type = EARLIEST_START
    end

    def self.from_yaml_object(yamlObj) #:nodoc:
      reference, activity = yamlObj.to_a[0]
      if reference == REFERENCE
        if !activity.nil?
          return Precedence::StartActivity.new(activity['description'])
        else
          return Precedence::StartActivity.new
        end
      else
        raise("A StartActivity can only have a reference of '#{REFERENCE}'."\
				" Given reference was '#{reference}'.")
      end
    end

    def add_pre_activities(*_pre_activities) #:nodoc:
      self
    end

    def register_pre_activity(_activity) #:nodoc:
      raise 'This activity can not be a post-activity of any other '\
			'activity.'
    end
  end

  # A special activity which signifies the finish of a precedence network.
  # It has a duration of 0 and is not allowed to have any post_activities.
  # It's reference will always be 'finish'.
  class FinishActivity < Precedence::Activity #:nodoc:
    attr_reader :expected_duration, :maximum_duration, :minimum_duration

    # Reference for the FinishActivity
    REFERENCE = 'finish'.freeze

    # Creates a new finish activity.
    def initialize(description = nil)
      @reference = REFERENCE
      @description = if description.nil?
                       @reference
                     else
                       description.to_s
                     end
      @expected_duration = 0
      @minimum_duration = 0
      @maximum_duration = 0
      @post_activities = []
      @pre_activities = []
      @resources = {}
      @duration_type = EXPECTED_DURATION
      @start_type = EARLIEST_START
    end

    def self.from_yaml_object(yamlObj) #:nodoc:
      reference, activity = yamlObj.to_a[0]
      if reference == REFERENCE
        if !activity.nil?
          return Precedence::FinishActivity.new(activity['description'])
        else
          return Precedence::FinishActivity.new
        end
      else
        raise "A FinishActivity can only have a reference of '#{REFERENCE}'."\
				" Given reference was '#{reference}'."
      end
    end

    def add_post_activities(*_post_activities) #:nodoc:
      self
    end

    def register_post_activity(_activity) #:nodoc:
      raise 'This activity can not be a pre-activity of any other '\
			'activity.'
    end
  end
end
