module Dishwasher
	class Dish < ActiveRecord::Base
		ACCEPT = [200, 201, 202, 203, 204, 205, 206, 300, 301, 302, 304]

		def self.dirty
			where("status NOT IN ?", ACCEPT)
		end

		def self.clean
			where("status IN ?", ACCEPT)
		end
	end
end