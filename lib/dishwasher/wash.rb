class Dishwasher::Wash < ActiveRecord::Base
	attr_accessible :table

	def has?(wash)
		find_by_table(wash).count > 0
	end
end