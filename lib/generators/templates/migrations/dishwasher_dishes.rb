class CreateDishwasherDishes < ActiveRecord::Migration
	def up
		create_table :dishwasher_dishes do |t|
			t.string :url
			t.integer :status
			t.string :klass
			t.string :error
			t.integer :record_id
			t.timestamps
		end
	end

	def down
		drop_table :dishwasher_dishes
	end
end
