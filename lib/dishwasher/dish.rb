module Dishwasher
	class Dish < ActiveRecord::Base
		def dirty
			where.not(status: 200)
		end

		def clean
			where(status: 200)
		end
	end
end