module Dishwasher
	module Generators
		module OrmHelpers
			private
				def model_exists?
					File.exists?(File.join(destination_root, model_path))
				end

				def migration_exists?
					Dir.glob("#{File.join(destination_root, migration_path)}/[0-9]*_*.rb").grep(/\d+_create_dishwasher_loads.rb$/).first
				end

				def migration_path
					@migration_path ||= File.join("db", "migrate")
				end

				def model_path
					@model_path ||= File.join("app", "models", "dishwasher.rb")
				end
		end
	end
end