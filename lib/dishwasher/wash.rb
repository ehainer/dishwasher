module Dishwasher
	class Wash < ActiveRecord::Base
		attr_accessible :table, :columns

		def self.ensure_washing(wash, dishes=[])
			unless find_by_table(wash).count > 0
				self[:table] = wash
				self[:columns] = dishes.join(",")
			end
			self
		end
	end
end