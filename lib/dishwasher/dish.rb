module Dishwasher
	class Dish < ActiveRecord::Base
		def self.dirty
			where.not(status: 200)
		end

		def self.clean
			where(status: 200)
		end
	end
end