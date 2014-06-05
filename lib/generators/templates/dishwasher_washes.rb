class CreateDishwasherWash < ActiveRecord::Migration
	def up
		create_table :dishwasher_washes do |t|
			t.string :table
		end
	end

	def down
		drop_table :dishwasher_washes
	end
end
