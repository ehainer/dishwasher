require 'dishwasher/wash'
require 'dishwasher/load'

module Dishwasher

	mattr_accessor :chunk_size
	@@chunk_size = 20

	mattr_accessor :tick_interval
	@@tick_interval = 10.minutes

	mattr_accessor :state
	@@state = {}

	def self.included(base)
		base.extend ClassMethods
	end

	module ClassMethods
		def wash(*args)
			::Dishwasher::Wash.ensure_washing(self, args)
		end
	end

	def self.table_name_prefix
		'dishwasher_'
	end

	def self.setup
		yield self
	end

	def self.run
		puts "Running Dishwasher... Aww Shit."
		begin
			invoke_all_models
			can_do_dishes?
			init_state
			load = Dishwasher::Load.new
			load.start
		rescue Dishwasher::Suds => e
			puts "Dishwasher Failed! " + e.to_s
		end
		puts "Dishwasher Stopped"
		puts ""
	end

	def self.has_recent_load?
		Dishwasher::Load.all.count > 0
	end

	def self.invoke_all_models
		Dir.glob(File.expand_path("app/models/**/*.rb", Rails.root)).each do |model_file|
			if model_file.end_with?(".rb")
				require model_file
			end
		end
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
		wash = Dishwasher::Wash.where(table: load.klass.to_s).first
		return get_initial_state if wash.nil?
		build_state(load.klass, load.offset, wash.columns)
	end

	def self.get_initial_state
		wash = Dishwasher::Wash.all.first
		build_state(wash[:table], 0, wash[:columns])
	end

	def self.build_state(klass, offset, columns)
		columns = columns.split(",") unless columns.kind_of?(Array)
		{ klass: klass.to_s, offset: offset, columns: columns }
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
		self.state[:klass] = next_table.to_s
		self.state[:offset] = 0
		self.state[:columns] = get_columns(next_table)
	end

	def self.can_do_dishes?
		raise Dishwasher::Suds.new("Nothing configured to scan.") if Dishwasher::Wash.all.count == 0
	end

	private

		def self.tables
			Dishwasher::Wash.select(:table).map(&:table)
		end

		def self.get_table
			tables.first
		end

		def self.get_columns(klass)
			wash = Dishwasher::Wash.where(table: klass).first
			unless wash.nil?
				return wash.columns.split(",")
			end
			[]
		end
end

module Exceptions
	class Dishwasher::Suds < StandardError
	end
end

class ActiveRecord::Base
	include Dishwasher
end