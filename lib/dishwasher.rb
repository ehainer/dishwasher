module Dishwasher

	mattr_accessor :chunk_size
	@@chunk_size = 20

	mattr_accessor :state
	@@state = {}

	mattr_accessor :scan
	@@scan = {}

	def self.included(base)
		base.extend ClassMethods
	end

	def ensure_unique(name)
		begin
			self[name] = yield
		end while self.class.exists?(name => self[name])
	end

	module ClassMethods
		def wash(*args)
			puts "---------------------"
			puts args.to_yaml
			puts "====================="
		end
	end

	def self.table_name_prefix
		'dishwasher_'
	end

	def self.setup
		yield self
	end

	def self.run
		puts ""
		puts ""
		puts "Running Dishwasher..."
		begin
			can_do_dishes
			init_state
			load = Dishwasher::Load.new
			load.start
		rescue Dishwasher::Suds => e
			puts "Dishwasher Failed! " + e.to_s
		end
		puts "Dishwasher Stopped"
		puts ""
		puts ""
	end

	def self.has_recent_load?
		Dishwasher::Load.all.count > 0
	end

	def self.init_state
		if has_recent_load?
			self.state = get_recent_state
		else
			self.state = get_initial_state
		end
	end

	def self.get_recent_state
		load = Dishwasher::Load.order("created_at DESC").limit(1).first
		return get_initial_state unless tables.map{ |k| k.camelize.constantize.to_s }.include?(load.klass)
		{ klass: load.klass, offset: load.offset, columns: get_columns(load.klass) }
	end

	def self.get_initial_state
		{ klass: tables.first, offset: 0, columns: get_columns }
	end

	def self.advance_table
		current = self.state[:klass]
		next_table = tables.first
		current_index = tables.index(current)
		unless current_index.nil?
			current_index += 1
			if current_index < tables.size
				next_table = tables[current_index]
			end
		end
		self.state[:klass] = next_table
		self.state[:offset] = 0
		self.state[:columns] = get_columns(next_table)
	end

	def self.can_do_dishes
		raise Dishwasher::Suds.new("Nothing configured to scan.") if self.scan.keys.size == 0
	end

	private

		def self.tables
			string_hash = Hash[self.scan.stringify_keys.map{ |k,v| [k.camelize.constantize.to_s, v] }]
			string_hash.keys
		end

		def self.get_table
			tables.first
		end

		def self.get_columns(klass=nil)
			columns = []
			string_hash = Hash[self.scan.stringify_keys.map{ |k,v| [k.camelize.constantize.to_s, v] }]
			unless klass.nil?
				columns = string_hash[klass]
			else
				columns = string_hash.values.first
			end
			columns = [columns] unless columns.kind_of?(Array)
			columns
		end
end

module Exceptions
	class Dishwasher::Suds < StandardError
	end
end

class ActiveRecord::Base
	include Dishwasher
end