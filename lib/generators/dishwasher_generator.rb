require 'rails/generators/base'
require 'rails/generators/actions'
require 'rails/generators/migration'
require 'generators/orm_helpers'
require 'fileutils'

module Dishwasher
	module Generators
		class DishwasherGenerator < Rails::Generators::Base
			include Dishwasher::Generators::OrmHelpers
			include Rails::Generators::Migration
			include Rails::Generators::Actions

			source_root File.expand_path("templates", File.dirname(__FILE__))

			def copy_initializer
				template "dishwasher_config.rb", "config/initializers/dishwasher.rb"
			end

			def copy_migrations
				unless migration_exists?
					copy_file "migrations/dishwasher_loads.rb", "db/migrate/#{migration_version}_create_dishwasher_loads.rb"
					copy_file "migrations/dishwasher_washes.rb", "db/migrate/#{migration_version}_create_dishwasher_washes.rb"
					copy_file "migrations/dishwasher_dishes.rb", "db/migrate/#{migration_version}_create_dishwasher_dishes.rb"
					rake "db:migrate"
				end
			end

			def copy_controllers
				unless File.exist?(File.expand_path("app/controllers/dishwasher_controller.rb", Rails.root))
					copy_file "controllers/dishwasher_controller.rb", "app/controllers/dishwasher_controller.rb"
					route "get '/dishwasher', to: 'dishwasher#index'"
				end
			end

			def copy_views
				unless File.exist?(File.expand_path("app/views/dishwasher/index.html.erb", Rails.root))
					FileUtils.mkdir_p(File.expand_path("app/views/dishwasher", Rails.root))
					copy_file "views/index.html.erb", "app/views/dishwasher/index.html.erb"
				end
			end

			def init_whenever
				unless File.exist?(File.expand_path("config/schedule.rb", Rails.root))
					exec("cd #{Rails.root} && wheneverize .")
				end

				unless File.readlines(File.expand_path("config/schedule.rb", Rails.root)).grep(/Dishwasher\.run/).size > 0
					schedule = File.open(File.expand_path("config/schedule.rb", Rails.root), "w")
					schedule.write "\r\n"
					schedule.write "every #{(Dishwasher.config.tick_interval.to_i/60).to_s}.minutes do"
					schedule.write "\trunner \"Dishwasher.run\""
					schedule.write "end"
					schedule.close
				end
				exec("cd #{Rails.root} && whenever --update-crontab")
			end

			def migration_version
				version = Time.now.utc.strftime("%Y%m%d%H%M%S").to_i
				while Dir.glob(File.expand_path("db/migrate/#{version.to_s}_*", Rails.root)).length > 0
					version = version+1
				end
				@migration_version = version
				@migration_version.to_s
			end
		end
	end
end