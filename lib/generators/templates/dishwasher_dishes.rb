class CreateDishwasherDishes < ActiveRecord::Migration
	def up
		create_table :dishwasher_dishes do |t|
			t.string :url
			t.integer :status
			t.timestamps
		end
	end

	def down
		drop_table :dishwasher_dishes
	end
end
