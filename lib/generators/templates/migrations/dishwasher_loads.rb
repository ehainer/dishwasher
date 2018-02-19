class CreateDishwasherLoads < ActiveRecord::Migration[4.2]
	def up
		create_table :dishwasher_loads do |t|
			t.string :klass
			t.integer :offset
			t.timestamps
		end
	end

	def down
		drop_table :dishwasher_loads
	end
end
