module Dishwasher
	class Wash < ActiveRecord::Base
		def self.ensure_washing(wash, dishes=[])
			dishes = dishes.join(",")
			existing = where(table: wash, columns: dishes)
			unless existing.length > 0
				create(table: wash, columns: dishes)
			end
			self
		end
	end
end