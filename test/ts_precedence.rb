require('test/unit')

require('./test/tc_activity')
require('./test/tc_network')

require('./lib/precedence/utilities')

class TS_Precedence < Test::Unit::TestSuite
	def initialize(name="Precedence Test Suite")
		super(name)
		@tests << TC_Activity.suite
		@tests << TC_StartFinishActivity.suite
		@tests << TC_ActivityHash.suite
		@tests << TC_Network.suite
	end
end
