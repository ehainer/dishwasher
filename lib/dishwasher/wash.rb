module Dishwasher
	class Wash < ActiveRecord::Base
		def self.ensure_washing(wash, dishes=[])
			dishes = dishes.join(",")
			existing = where(klass: wash.to_s, columns: dishes)
			unless existing.length > 0
				where(klass: wash.to_s).destroy_all
				create(klass: wash.to_s, columns: dishes)
			end
		end
	end
end