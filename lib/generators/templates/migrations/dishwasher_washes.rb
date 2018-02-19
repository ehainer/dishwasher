class CreateDishwasherWashes < ActiveRecord::Migration[4.2]
	def up
		create_table :dishwasher_washes do |t|
			t.string :klass
			t.string :columns
		end
	end

	def down
		drop_table :dishwasher_washes
	end
end
