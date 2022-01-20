# Requirements from Ruby standard library
require('erb')
require('yaml')

module Precedence
  # Represents an entire precedence network. It wraps around an underlying
  # directed graph of Activity objects and adds a number of utility methods
  # and extra functionality that would not be available if one just used
  # Activity objects.
  class Network
    # A hashed collection of all the activities in the network. The index
    # is the reference of the activity.
    attr_reader :activities

    # The reference for the StartActivity in the network.
    START = Precedence::StartActivity::REFERENCE

    # The reference for the FinishActivity in the network.
    FINISH = Precedence::FinishActivity::REFERENCE

    # Initialises the precedence network. The descriptions for the start
    # and finish activities can be set in the parameters. The start and
    # finish activities of the network have as references 'start' and
    # 'finish' (held in constants Network::START and Network::FINISH)
    # respectively (and as such these references are reserved)
    # and a duration of 0.
    #
    # Example usage:
    #  precNetwork = Precedence::Network.new('Begin','End')
    # will create a new precedence network with the start and finish
    # activities having descriptions of 'Begin' and 'End' respectively.
    def initialize
      @start = Precedence::StartActivity.new
      @finish = Precedence::FinishActivity.new
      @activities = Precedence::Utilities::ActivityHash.new(@start, @finish)
      # @activities[START] = @start
      # @activities[FINISH] = @finish
    end

    # Creates a new activity and adds it to the precedence network. The
    # reference is the only mandatory parameter. This method will take the
    # block given and pass it to the Activity.new method.
    #
    # Exapmple usage:
    #  precNetwork.new_activity('a2') do |activity|
    #   activity.duration = 3
    #   activity.description = 'Activity2'
    #  end
    #  precNetwork.connect('a2','a1')
    # will create a new activity in the network with referecne 'a2' and with
    # activity 'a1' as a post-activity.
    def new_activity(reference, &block)
      activity = Precedence::Activity.new(reference, &block)
      activities[reference] = activity
    end

    # Adds a Precedence::Activity object to the network. This should be a
    # single activity (no pre- or post-activities should be referenced from
    # it) and it's reference should not exist in the network.
    #
    # Example usage:
    #  activity = Precedence::Activity.new('a1',1,'Activity 1')
    #  precNetwork.add_activity(activity)
    # will add the existing activity 'a1' to the network.
    def add_activity(activity)
      if reference_exists?(activity.reference)
        raise "Activity #{activity.reference} already exists in the "\
 					'network.'
      end

      unless activity.post_activities == []
        raise 'Can not add an activity with post activities.'
      end

      unless activity.pre_activities == []
        raise 'Can not add an activity with pre activities.'
      end

      @activities[activity.reference] = activity
    end

    # Connects two or more activities together. The pre_ref activity will
    # become a pre-activity to all the activities referenced in the
    # post_refs parameter.
    #
    # Example uysage:
    #  precNetwork.connect(:h1,:h2,:h3)
    # will add activity 'h1' as a pre-activity to activities 'h2' and 'h3'.
    def connect(pre_ref, *post_refs)
      unless reference_exists?(pre_ref)
        raise "Pre-activity with reference #{pre_ref} "\
 					'was not found.'
      end

      post_refs.each do |post_ref|
        unless reference_exists?(post_ref)
          raise "Post-activity with reference #{post_ref} "\
 						'was not found.'
        end
      end

      post_refs.each do |post_ref|
        activities[pre_ref].add_post_activities(activities[post_ref])
      end
    end

    # Disconnects an activity from one or more post activities.
    #
    # Example usage:
    #  precNetwork.disconnect(:h1,:h2,:h3)
    # will remove activity 'h1' as a pre-activity to activities 'h2' and
    # 'h3'.
    def disconnect(pre_ref, *post_refs)
      unless reference_exists?(pre_ref)
        raise "Pre-activity with reference #{pre_ref} "\
 					'was not found.'
      end

      post_refs.each do |post_ref|
        unless reference_exists?(post_ref)
          raise "Post-activity with reference #{post_ref} "\
 						'was not found.'
        end
      end

      post_refs.each do |post_ref|
        activities[pre_ref].remove_post_activities(activities[post_ref])
      end
    end

    # Returns true if the reference is currently in the network. This
    # includes START and FINISH.
    def reference_exists?(reference)
      if !activities[reference].nil? ||
         (reference == START) ||
         (reference == FINISH)
        return true
      end
      false
    end

    # Ensures that the network is properly connected by connecting any
    # activity without pre-activities to the start node and to the finish
    # node if it has no post-activities. Must be called before any analysis
    # on the network is done.
    #
    # Example usage:
    #  precNetwork.connect('h1','h2')
    #  precNetwork.connect('h2','h3','h4)
    #  precNetwork.fix_connections!
    #  precNetwork.finish
    #  precNetwork.activities['h2'].earliest_finish
    def fix_connections!
      activities.each do |ref, activity|
        connect(START, ref) if activity.pre_activities.empty?

        connect(ref, FINISH) if activity.post_activities.empty?
      end
    end

    # Returns a dot file capable of being rendered by the Dot graph renderer
    # available from GraphViz (http://www.graphviz.org).
    #
    # Example usage:
    #  File.open('test_to_dot.dot',File::CREAT|File::TRUNC|File::WRONLY) do|f|
    #   f.puts(net.to_dot)
    #  end
    def to_dot(template = nil)
      template ||= Precedence::Network.get_rdot_template
      ERB.new(template).result(binding)
    end

    # Returns a YAML representation of the network.For more information on
    # YAML go to http://yaml.org
    #
    # Example usage:
    #  File.open('test_to_yaml.yaml',File::CREAT|File::TRUNC|File::WRONLY) do|f|
    #   f.puts(net.to_yaml)
    #  end
    def to_yaml
      activities.values.map(&:to_yaml).join("\n")
    end

    # Returns a Precedence::Network object that is represented by the
    # YAML document.
    #
    # Example usage:
    #  precNetwork = nil
    #  File.open('precnetwork.yaml',File::RDONLY) do |f|
    #   precNetwork = Precedence::Network.from_yaml(f)
    #  end
    def self.from_yaml(yaml)
      activities = {}
      connections = {}

      YAML.load_documents(yaml) do |doc|
        activity = Precedence::Activity.from_yaml_object(doc)
        activities[activity.reference] = activity
        connections[activity.reference] =
          doc[activity.reference]['post activities']
      end

      network = Precedence::Network.new

      activities.values.each do |activity|
        unless (activity.reference == START) ||
               (activity.reference == FINISH)
          network.add_activity(activity)
        end
      end

      connections.each do |ref, connections|
        connections.to_a.each do |post_ref|
          network.connect(ref, post_ref)
        end
      end
      network
    end

    # The time it will take to finish all activities in the network.
    # (Shortcut to precNetwork.activities['finish'].finish)
    #
    # Example usage:
    #  precNetwork.finish
    def finish
      @finish.finish
    end

    # Iterates over the networks duration yielding an array of activities
    # that are active at that time to a block. The size of the time jumps
    # can be set using the tick parameter. The duration starts at time 0
    # and ends at time network.finish - tick.
    #
    # Example usage:
    #  precNetwork.each_time_period do |activities|
    #    coffeeUsed == 0
    #    activities.each do |activity|
    #      coffeeUsed += activity.resources['coffee']
    #    end
    #    puts "Used #{coffeeUsed} units of coffee in #{activities.size} activities."
    # end
    def each_time_period(tick = 1)
      0.step(finish - tick, tick) do |current_time|
        yield(activities_at_time(current_time))
      end
    end

    # The same functionality as each_time_period except that the time is
    # yielded along with the array of active activities.
    #
    # Example usage:
    #  precNetwork.each_time_period_with_index do |activities,time|
    #    puts "At time #{time}, #{activities.size} activities were active."
    #  end
    def each_time_period_with_index(tick = 1)
      0.step(finish - tick, tick) do |current_time|
        yield(activities_at_time(current_time), current_time)
      end
    end

    # Returns an array of activities with each activity being active at
    # the time of the parameter.
    def activities_at_time(time)
      (@activities.values.select do |activity|
        activity.active_on?(time)
      end)
    end

    # Returns an array of activities with each acitivity being active
    # deuring the time range of the parameter
    def activities_during_time(range)
      (@activities.values.select do |activity|
        activity.active_during?(range)
      end)
    end

    # Returns the rdot (Ruby embedded in a dot file) template that is used
    # by default when generating the precedence network diagrams.
    def self.get_rdot_template #:nodoc:
      <<END_OF_STRING
/* Generated by Precedence on <%= Time.now.to_s %> */
digraph network {
	rankdir=LR;
	node [shape=record];

	/* Activities */
	<% @activities.each do |ref,activity| %>
		<% case ref
			when START%>
	"<%= ref %>" [label="<%= activity.description %>"];
		 <% when FINISH %>
	"<%= ref %>" [label="{<%= activity.description%>|<%= activity.earliest_finish %>}"];
		 <% else %>
	"<%= ref %>" [label="<%=ref%>|{{<%=activity.earliest_start%>|<%=activity.latest_start%>}|{<%=activity.description%>|{<%=activity.total_float%>|<%=activity.early_float%>}}|{<%=activity.earliest_finish%>|<%=activity.latest_finish%>}}|<%=activity.duration%>"];
		<% end %>
	<% end %>

	/* Dependencies */
	<% @activities.each do |ref,activity|%>
		<% activity.post_activities.each do |post_activity| %>
	"<%= activity.reference %>" -> "<%= post_activity.reference %>" <% if (activity.on_critical_path? and post_activity.on_critical_path?)%>[style=bold]<% end %>;
		<% end %>
	<% end %>
}
END_OF_STRING
    end
  end
end
