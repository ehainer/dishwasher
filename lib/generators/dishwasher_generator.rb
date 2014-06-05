require 'rails/generators/base'
require 'rails/generators/migration'
require 'generators/orm_helpers'

module Dishwasher
	module Generators
		class DishwasherGenerator < Rails::Generators::Base
			include Dishwasher::Generators::OrmHelpers
			include Rails::Generators::Migration

			source_root File.expand_path("templates", File.dirname(__FILE__))

			def copy_initializer
				template "dishwasher_config.rb", "config/initializers/dishwasher.rb"
			end

			def copy_migrations
				unless migration_exists?
					copy_file "dishwasher_loads.rb", "db/migrate/#{migration_version}_create_dishwasher_loads.rb"
					copy_file "dishwasher_washes.rb", "db/migrate/#{migration_version}_create_dishwasher_washes.rb"
					rake "db:migrate"
				end
			end

			def migration_version
				@migration_version ||= Time.now.utc.strftime("%Y%m%d%H%M%S").to_i
				version = Time.now.utc.strftime("%Y%m%d%H%M%S").to_i
				while version == @migration_version
					version += 1
				end
				@migration_version = version
				@migration_version.to_s
			end
		end
	end
end