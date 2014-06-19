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

		def self.scrub(dish)
			existing = where(klass: dish.class.name.to_s).first
			unless existing.nil?
				load = Dishwasher::Load.new
				data = []
				columns = existing.columns.split(",")
				columns.each do |column|
					data << { id: dish.id, klass: dish.class.name.to_s, content: dish[column] }
				end
				puts data
				urls = load.parse_data(data)
				urls = [urls] unless urls.kind_of?(Array)
				puts urls
				load.check_urls(urls)
			end
		end
	end
end