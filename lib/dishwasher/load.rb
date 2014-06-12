require "net/http"
require "uri"
require "dishwasher/dish"

module Dishwasher
	class Load < ActiveRecord::Base

		DEFAULT_STATUS = 500

		def start
			@data ||= []
			@select_count = Dishwasher.chunk_size
			load_data
			update_load
			urls = parse_data
			check_urls(urls)
		end

		def load_data
			while has_results? do
				add_data(select_available)
			end
			@data.reject!{ |x| x[:content].nil? || x[:content].strip == "" }
		end

		def parse_data
			urls = []
			regexp = /(?i)\b((?:https?:(?:\/{1,3}|[a-z0-9%])|[a-z0-9.\-]+[.](?:com|net|org|edu|gov|mil|aero|asia|biz|cat|coop|info|int|jobs|mobi|museum|name|post|pro|tel|travel|xxx|ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cs|cu|cv|cx|cy|cz|dd|de|dj|dk|dm|do|dz|ec|ee|eg|eh|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gg|gh|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|je|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|me|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|rs|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|Ja|sk|sl|sm|sn|so|sr|ss|st|su|sv|sx|sy|sz|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|yu|za|zm|zw)\/)(?:[^\s()<>{}\[\]]+|\([^\s()]*?\([^\s()]+\)[^\s()]*?\)|\([^\s]+?\))+(?:\([^\s()]*?\([^\s()]+\)[^\s()]*?\)|\([^\s]+?\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’])|(?:(?<!@)[a-z0-9]+(?:[.\-][a-z0-9]+)*[.](?:com|net|org|edu|gov|mil|aero|asia|biz|cat|coop|info|int|jobs|mobi|museum|name|post|pro|tel|travel|xxx|ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cs|cu|cv|cx|cy|cz|dd|de|dj|dk|dm|do|dz|ec|ee|eg|eh|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gg|gh|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|je|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|me|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|rs|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|Ja|sk|sl|sm|sn|so|sr|ss|st|su|sv|sx|sy|sz|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|yu|za|zm|zw)\b\/?(?!@)))/i
			@data.each do |record|
				matches = record[:content].scan(regexp)
				if matches.length > 0
					urls << { urls: matches.flatten, id: record[:id], klass: record[:klass] }
				end
			end
			urls
		end

		def update_load
			@data ||= []
			self[:klass] = @data.length > 0 ? @data.last[:klass] : Dishwasher.state[:klass]
			self[:offset] = Dishwasher.state[:offset]
			self.save
			self
		end

		def check_urls(records)
			records.each do |record|
				record[:urls].each do |url|

					url = "http://" + url if !url.start_with?("http://") && !url.start_with?("https://")
					url += "/" if url =~ /\.[a-z]+$/i

					code = DEFAULT_STATUS

					recent_lookup = find_recent_lookup(url)

					if recent_lookup == false
						begin
							response = fetch(url)
							code = response.code
						rescue Dishwasher::Suds => e
						rescue Net::OpenTimeout => e
							code = 504
						rescue Net::ReadTimeout => e
							code = 504
						rescue Exception => e
							code = 404 if e.to_s.include?("404")
						end
					else
						code = recent_lookup.status
					end

					unless url.to_s.strip == ""
						Dishwasher::Dish.find_or_initialize_by(url: url.to_s, klass: record[:klass], record_id: record[:id]) do |dish|
							dish.status = code
							dish.save
						end
					end
				end
			end
		end

		def fetch(uri_str, limit = 10)
			raise Dishwasher::Suds.new("Redirect limit reached") if limit == 0

			ua = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/36.0.1944.0 Safari/537.36"

			uri = URI.parse(uri_str)
			http = Net::HTTP.new(uri.host, uri.port)
			http.open_timeout = 10
			http.read_timeout = 10
			http.use_ssl = true if uri.scheme == 'https'

			response = http.start do
				request = Net::HTTP::Get.new(uri.request_uri, { 'User-Agent' => ua })
				http.request(request)
			end

			case response
				when Net::HTTPSuccess then
					response
				when Net::HTTPRedirection then
					if response['location'].nil?
						fetch(response.body.match(/<a href=\"([^>]+)\">/i)[1], limit-1)
					else
						fetch(response['location'], limit-1)
					end
				else
					response.error!
			end
		end

		def find_recent_lookup(url)
			dish = Dishwasher::Dish.where(url: url).where("updated_at > ?", 10.minutes.ago)
			if dish.count > 0
				dish.first
			else
				false
			end
		end

		def add_data(results)
			i = 1
			results.each do |result|
				Dishwasher.state[:columns].each do |column|
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
			return true if @select_count+Dishwasher.state[:offset] > total_rows && total_rows > 0
			false
		end

		def must_advance?
			total_rows = table.all.count
			return true if Dishwasher.state[:offset] >= total_rows && total_rows > 0
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

			Dishwasher.state[:offset] += data.length

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
			results = table.select(:id, Dishwasher.state[:columns]).offset(Dishwasher.state[:offset])
			@select_count = @select_count-results.length
			results
		end

		def select_remainder
			results = table.select(:id, Dishwasher.state[:columns]).limit(@select_count).offset(Dishwasher.state[:offset])
			@select_count = @select_count-results.length
			results
		end

		def table
			Dishwasher.state[:klass].constantize
		end
	end
end