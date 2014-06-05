class Dishwasher::Load < ActiveRecord::Base
	attr_accessible :offset, :klass

	def start
		@data ||= []
		@select_count = Dishwasher.chunk_size
		load_data
		update_load
	end

	def load_data
		while has_results? do
			add_data(select_available)
		end
		@data.reject!{ |x| x[:content].nil? || x[:content].strip == "" }
	end

	def update_load
		@data ||= []
		self[:klass] = @data.length > 0 ? @data.last[:klass] : Dishwasher.state[:klass]
		self[:offset] = Dishwasher.state[:offset]
		self.save
		self
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
		return true if @select_count+Dishwasher.state[:offset] > total_rows
		false
	end

	def must_advance?
		total_rows = table.all.count
		return true if Dishwasher.state[:offset] >= total_rows
		false
	end

	def has_results?
		@select_count > 0
	end

	def select_available
		data = []
		if can_select_all?
			puts "SELECT ALL"
			data = select_all
		else
			puts "REMAINDER"
			data = select_remainder
		end

		Dishwasher.state[:offset] += data.length

		if must_advance?
			Dishwasher.advance_table
			puts Dishwasher.state
		end
		data
	end

	def select_all
		#results = Dishwasher::Load.find_by_sql("SELECT *, '#{Dishwasher.state[:klass]}' AS klass FROM #{table.table_name} OFFSET #{Dishwasher.state[:offset]}")
		results = table.select(Dishwasher.state[:columns]).offset(Dishwasher.state[:offset])
		puts "Result Size For " + table.to_s + ": " + results.length.to_s
		@select_count = @select_count-results.length
		results
	end

	def select_remainder
		#results = Dishwasher::Load.find_by_sql("SELECT *, '#{Dishwasher.state[:klass]}' AS klass FROM #{table.table_name} LIMIT #{@select_count} OFFSET #{Dishwasher.state[:offset]}")
		results = table.select(Dishwasher.state[:columns]).limit(@select_count).offset(Dishwasher.state[:offset])
		puts "Result Size For " + table.to_s + ": " + results.length.to_s
		@select_count = @select_count-results.length
		results
	end

	def table
		Dishwasher.state[:klass].camelize.constantize
	end
end