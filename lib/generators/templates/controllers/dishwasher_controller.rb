class DishwasherController < ApplicationController
	def index
		@dishes = Dishwasher::Dish.dirty
	end
end