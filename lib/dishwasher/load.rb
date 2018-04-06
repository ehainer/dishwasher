require "uri"
require "rest_client"
require "dishwasher/dish"

module Dishwasher
	class Load < ActiveRecord::Base

		DEFAULT_STATUS = 700

		ACCEPT = [200, 201, 202, 203, 204, 205, 206, 300, 301, 302, 303, 304]

		def start
			@data ||= []
			@select_count = Dishwasher.chunk_size
			load_data
			update_load
			urls = parse_data(@data)
			check_urls(urls)
		end

		def load_data
			while has_results? do
				add_data(select_available)
			end
			@data.reject!{ |x| x[:content].nil? || x[:content].strip == "" }
		end

		def parse_data(data)
			urls = []
			regexp = /(?i)\b((?:https?:(?:\/{1,3}|[a-z0-9%])|[a-z0-9.\-]+[.](?:com|net|org|edu|gov|mil|aero|asia|biz|cat|coop|info|int|jobs|mobi|museum|name|post|pro|tel|travel|xxx|ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cs|cu|cv|cx|cy|cz|dd|de|dj|dk|dm|do|dz|ec|ee|eg|eh|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gg|gh|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|je|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|me|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|rs|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|Ja|sk|sl|sm|sn|so|sr|ss|st|su|sv|sx|sy|sz|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|yu|za|zm|zw)\/)(?:[^\s()<>{}\[\]]+|\([^\s()]*?\([^\s()]+\)[^\s()]*?\)|\([^\s]+?\))+(?:\([^\s()]*?\([^\s()]+\)[^\s()]*?\)|\([^\s]+?\)|[^\s`!()\[\]{};:'".,<>?])|(?:(?<!@)[a-z0-9]+(?:[.\-][a-z0-9]+)*[.](?:com|net|org|edu|gov|mil|aero|asia|biz|cat|coop|info|int|jobs|mobi|museum|name|post|pro|tel|travel|xxx|ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cs|cu|cv|cx|cy|cz|dd|de|dj|dk|dm|do|dz|ec|ee|eg|eh|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gg|gh|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|je|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|me|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|rs|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|Ja|sk|sl|sm|sn|so|sr|ss|st|su|sv|sx|sy|sz|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|yu|za|zm|zw)\b\/?(?!@)))/i
			data.each do |record|
				unless record[:content].nil?
					matches = record[:content].scan(regexp)
					if matches.length > 0
						urls << { urls: matches.flatten, id: record[:id], klass: record[:klass] }
					end
				end
			end
			urls
		end

		def update_load
			@data ||= []
			self[:klass] = @data.length > 0 ? @data.last[:klass] : Dishwasher.dish_state[:klass]
			self[:offset] = Dishwasher.dish_state[:offset]
			self.save
			self
		end

		def check_urls(records)
			records.each do |record|
				record[:urls].each do |url|
					code = DEFAULT_STATUS

					error = ""

					recent_lookup = find_recent_lookup(url)

					if recent_lookup == false
						begin
							response = fetch(url)
							code = response.code.to_i
						rescue Dishwasher::Suds => e
							error = e.to_s
						rescue Exception => e
							error = e.to_s
							if e.respond_to?(:http_code)
								code = e.http_code
							end
						end
					else
						code = recent_lookup.status
					end

					dish = Dishwasher::Dish.find_or_initialize_by(url: url.to_s, klass: record[:klass], record_id: record[:id])
					dish.error = error[0..250].force_encoding('iso8859-1').encode('utf-8')
					dish.status = code
					dish.checked = (dish.checked || 0) + 1
					dish.updated_at = Time.now
					dish.save

					dish.delete if dish.checked > Dishwasher.max_checks

					if ACCEPT.include?(code)
						Dishwasher::Dish.where("klass = ? AND record_id = ? AND status NOT IN (?)", record[:klass], record[:id], ACCEPT).delete_all
					end
				end
			end
		end

		def fetch(uri_str)
			uri_str = uri_str.strip
			uri_str = "ftp://" + uri_str if !uri_str.start_with?("http://") && !uri_str.start_with?("https://") && uri_str.start_with?("ftp.")
			uri_str = "http://" + uri_str if !uri_str.start_with?("http://") && !uri_str.start_with?("https://") && !uri_str.start_with?("ftp://")
			uri_str = uri_str.chomp("/")

			RestClient.get uri_str
		end

		def find_recent_lookup(url)
			return false
#			dish = Dishwasher::Dish.where(url: url).where("updated_at > ?", 10.minutes.ago).first
#			unless dish.nil?
#				dish
#			else
#				false
#			end
		end

		def add_data(results)
			i = 1
			results.each do |result|
				result.class.instance_variable_get("@__dishwasher_columns").each do |column|
					if column.to_s != "id"
						@data << { id: result[:id], klass: result.class.name.to_s, content: result[column] }
					end
				end
				i += 1
			end
			self
		end

		def can_select_all?
			@select_count ||= Dishwasher.chunk_size
			total_rows = table.all.count
			return true if @select_count+Dishwasher.dish_state[:offset] > total_rows && total_rows > 0
			false
		end

		def must_advance?
			total_rows = table.all.count
			return true if Dishwasher.dish_state[:offset] >= total_rows && total_rows > 0
			false
		end

		def has_results?
			@select_count > 0
		end

		def select_available
			data = []
			if can_select_all?
				data = select_all
			else
				data = select_remainder
			end

			Dishwasher.dish_state[:offset] += data.length

			if Dishwasher.tables.size == 1 && data.length == 0
				@select_count = 0
				return []
			end

			if must_advance?
				Dishwasher.advance_table
			end
			data
		end

		def select_all
			to_select = [:id] | Dishwasher.dish_state[:columns]
			results = table.select(to_select.flatten).offset(Dishwasher.dish_state[:offset])
			@select_count = @select_count-results.length
			results
		end


		def select_remainder
			to_select = [:id] | Dishwasher.dish_state[:columns]
			results = table.select(to_select.flatten).limit(@select_count).offset(Dishwasher.dish_state[:offset])
			@select_count = @select_count-results.length
			results
		end

		def table
			Dishwasher.dish_state[:klass].constantize
		end
	end
end