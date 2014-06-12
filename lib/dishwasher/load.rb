require "net/http"
require "uri"
require "dishwasher/dish"

module Dishwasher
	class Load < ActiveRecord::Base
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
				urls =  urls | record[:content].scan(regexp)
			end
			urls.uniq.flatten
		end

		def update_load
			@data ||= []
			self[:klass] = @data.length > 0 ? @data.last[:klass] : Dishwasher.state[:klass]
			self[:offset] = Dishwasher.state[:offset]
			self.save
			self
		end

		def check_urls(urls)
			urls.each do |url|
				if !url.start_with?("http://") && !url.start_with?("https://")
					url = "http://" + url
				end

				url += "/" if url =~ /\.[a-z]+$/i

				begin
					response = fetch(url)
					unless url.to_s.strip == ""
						Dishwasher::Dish.find_or_initialize_by(url: url.to_s) do |dish|
							dish.status = response.code
							dish.save
						end
					end
				rescue Dishwasher::Suds => e
					puts "========= Suds =========="
					puts url
					puts e.to_s
				rescue Net::OpenTimeout => e
					puts "========= Open Timeout =========="
					puts url
				rescue Net::ReadTimeout => e
					puts "========= Read Timeout =========="
					puts url
				rescue Exception => e
					puts "========= Exception =========="
					puts url
					puts e.to_s
				end
			end
		end

		def fetch(uri_str, limit = 10)
			raise Dishwasher::Suds.new("Redirect limit reached") if limit == 0

			ua = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/36.0.1944.0 Safari/537.36"
			url = URI.parse(uri_str)
			req = Net::HTTP::Get.new(url.path, { 'User-Agent' => ua })
			response = Net::HTTP.start(url.host, url.port) { |http|
				http.open_timeout = 10
				http.read_timeout = 30
				http.request(req)
			}
			case response
				when Net::HTTPSuccess then
					response
				when Net::HTTPRedirection then
					fetch(response['location'], limit-1)
				else
					response.error!
			end
		end

		def add_data(results)
			i = 1
			results.each do |result|
				Dishwasher.state[:columns].each do |column|
					if column.to_s != "id"
						@data << { id: result[:id], klass: result.class.name, content: result[column] }
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